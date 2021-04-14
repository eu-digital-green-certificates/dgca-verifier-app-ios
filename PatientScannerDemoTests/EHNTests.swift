//
//  EHNTests.swift
//  EHNTests
//
//  Created by Dirk-Willem van Gulik on 01/04/2021.
//

@testable import PatientScannerDemo
import XCTest
import CryptoKit
import SwiftCBOR

var barcode = "HC1NCFY70R30FFWTWGSLKC 4O992$V M63TMF2V*D9LPC.3EHPCGEC27B72VF/347O4-M6Y9M6FOYG4ILDEI8GR3ZI$15MABL:E9CVBGEEWRMLE C39S0/ANZ52T82Z-73D63P1U 1$PKC 72H2XX09WDH889V5"

let trust_json = """
[
  {
    \"kid\" : \"DEFBBA3378B322F5\",
    \"coord\" : [
      \"230ca0433313f4ef14ec0ab0477b241781d135ee09369507fcf44ca988ed09d6\",
      \"bf1bfe3d2bda606c841242b59c568d00e5c8dd114d223b2f5036d8c5bc68bf5d\"
    ]
  },
  {
    \"kid\" : \"FFFBBA3378B322F5\",
    \"coord\" : [
      \"9999a0433313f4ef14ec0ab0477b241781d135ee09369507fcf44ca988ed09d6\",
      \"9999fe3d2bda606c841242b59c568d00e5c8dd114d223b2f5036d8c5bc68bf5d\"
    ]
  }
]
"""


class EHNTests: XCTestCase {

  func test_cose() throws {
    let COSE_TAG = UInt64(18)
    let COSE_PHDR_SIG = CBOR.unsignedInt(1)
    let COSE_PHDR_KID = CBOR.unsignedInt(4)

    // Remove HC1 header if any
    if (barcode.hasPrefix("HC1")) {
      barcode = String(barcode.suffix(barcode.count-3))
    }

    guard
      let compressed = try? barcode.fromBase45()
    else { return }

    let data = decompress(compressed)
    let decoder = SwiftCBOR.CBORDecoder(input: data.uint)

    guard
      let cose = try? decoder.decodeItem(),
      case let CBOR.tagged(tag, cborElement) = cose,
      tag.rawValue == COSE_TAG, // SIGN1
      case let CBOR.array(array) = cborElement,
      case let CBOR.byteString(protectedBytes) = array[0],
      case let CBOR.map(unprotected) = array[1],
      case let CBOR.byteString(payloadBytes) = array[2],
      case let CBOR.byteString(signature) = array[3],
      let protected = try? CBOR.decode(protectedBytes),
      let payload = try? CBOR.decode(payloadBytes),
      case let CBOR.map(protectedMap) = protected
    else {
      return
    }
    var kid: [UInt8] = []
    let sig = protectedMap[COSE_PHDR_SIG]!

    print("SIG: ", sig)
    if case let CBOR.byteString(k) = protectedMap[COSE_PHDR_KID] ?? .null {
      kid = k
    }

    print("Signature: ", signature)
    print("Payload: ", payload)
    print("KID: ", kid)

    let externalData = CBOR.byteString([])
    let signed_payload: [UInt8] = CBOR.encode(
      [
        "Signature1",
        array[0],
        externalData,
        array[2]
      ]
    )
    let d = Data(bytes: signed_payload, count: signed_payload.count)
    print("Signing: ", d.base64EncodedString())
    let digest = SHA256.hash(data: signed_payload)
    print("Digest: ", digest)

    var publicKey: P256.Signing.PublicKey
    let signatureForData = try! P256.Signing.ECDSASignature(rawRepresentation: signature)

    // use KID to find the right X,Y coordinates from the JSON
    //
    struct TE : CustomStringConvertible {
      var description: String
      let kid : String
      //let coord : Array()
    }
    var x: [UInt8] = []
    var y: [UInt8] = []

    let _ = unprotected // unused

    do {
      if let trust = try JSONSerialization.jsonObject(with: trust_json.data(using: .utf8)!, options: []) as? [[String: Any]] {
        for case let elem : Dictionary in trust {
          if kid == Data(hexString: elem["kid"] as! String)?.uint {
            print("We know this KID - check if this sig works...")
            x = Data(hexString: ((elem["coord"] as! Array<Any>)[0] as? String) ?? "")?.uint ?? []
            y = Data(hexString: ((elem["coord"] as! Array<Any>)[1] as? String) ?? "")?.uint ?? []

            var rawk: [UInt8] = [04]
            rawk.append(contentsOf: x)
            rawk.append(contentsOf: y)
            XCTAssert(rawk.count == 32+32+1)

            publicKey = try! P256.Signing.PublicKey(x963Representation: rawk)

            if (publicKey.isValidSignature(signatureForData, for: digest)) {
              print("All is WELL !")

              print("Payload (decoded)")
              print(array[2]);
              return
            }
            print("- sig failed - which is OK - we may have more matching KIDS --")
          }
          print("Nope - all failed - sadness all around")
          assert(false)
        }
      }
    } catch let error as NSError {
      print("JSON parse trust list failed: ",error.localizedDescription)
    }
  }
}
