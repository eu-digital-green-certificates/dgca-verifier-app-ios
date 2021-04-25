//
//  EHNTests.swift
//  EHNTests
//
//  Created by Dirk-Willem van Gulik on 01/04/2021.
//

@testable import DGCAVerifier
import XCTest

class EHNTests: XCTestCase {
  func testCoseEcdsa() throws {
    var barcode = "HC1:NCFY70R30FFWTWGSLKC 4O992$V M63TMF2V*D9LPC.3EHPCGEC27B72VF/347O4-M6Y9M6FOYG4ILDEI8GR3ZI$15MABL:E9CVBGEEWRMLE C39S0/ANZ52T82Z-73D63P1U 1$PKC 72H2XX09WDH889V5"

    let trustJson = """
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

    // Remove HC1 header if any (v0.0.3 'HC1', v0.0.4 'HC1:')
    //
    if (barcode.hasPrefix("HC1:")) {
      barcode = String(barcode.suffix(barcode.count-4))
    }

    guard
      let compressed = try? barcode.fromBase45()
    else {
      XCTAssert(false)
      return
    }

    let data = decompress(compressed)

    guard
      let payload = CBOR.payload(from: data),
      let kid = CBOR.kid(from: data),
      let trustData = trustJson.data(using: .utf8),
      let trustSerialization = try? JSONSerialization.jsonObject(with: trustData, options: []),
      let trust = trustSerialization as? [[String: Any]]
    else {
      XCTAssert(false)
      return
    }
    for case let elem: Dictionary in trust {
      if
        kid == Data(hexString: elem["kid"] as! String)?.uint,
        let x = (elem["coord"] as? Array<Any>)?[0] as? String,
        let y = (elem["coord"] as? Array<Any>)?[1] as? String
      {
        print("We know this KID - check if this sig works...")
        if COSE.verify(data, with: x, and: y) {
          print("All is well! Payload: ", payload)
          return
        }
        print("- sig failed - which is OK - we may have more matching KIDS --")
      }
    }
    print("Nope - all failed - sadness all around")
    XCTAssert(false)
  }
  func testCoseEcAT() throws {
    let barcode = "HC1:NCFC:M/8OBK2 53WGEI1J%1IEAKE%GKV5B8M38S78UU+RRIR+1CT013E9ZI8$*NVQE+PQKR434V:-NN551/A*HSD87*JGTPKU77HTHOTIY/9VPKP859+1Q-1JCFL:O8SBM:5I%7X2NRAQ1XL0$E867W1FH-NIAWOQJEFELCNXMT7S739DJ2G2*CYG9IEMEU7/.B%E9 $0DKJPRIK-RRX2WBPOFE32TW HL24/YI4SO5LF04NZ-D O9$K9$IHYTC4JB622YMQ.5LVXH64JFGG-L0LJTW88O.L5T48AW2MTJD8CL4OUE4V2HX88FAH 89NKJS2SMPU%I8OC0AEPJ0 F2SMTERNC7CM20P00C9L8MBI.PMP9WWG6ICY$FK/QARHN+JX8S24UU00CEAA:SQUTY0LPRGQXVN6Q*UR-WH/FC8CJQ8WLBJH$47O8+.GMF78*A85H1GU4SPNC3TVKQBK:7C836%WI/QR$EC0YE:E77%LHAE5T07AVLUPLW38MMNF00 CE9U$-VKYU ZN1V3C:M9YH.RDK%VQSC.GRN29JSENCEX7SQ.J6:4D28Z*E*3V5/R6Q7*:3I R+1GUZQ$LBB 7B-E2KTU/0X1B- UKUJJ2U0.H 0RM2GBGIQ+M"
    return baseTestAT(barcode: barcode)
  }
  func testCoseRsaAT() throws {
    let barcode = "HC1:NCFOXNYTS3DH$YO:CQSU40 H 804 2FI15B3LR5OGILG9N:5-RII9DL-VAD65D6 NI4EFFZSE+S.SSH2HGUS XKVD9HB58QHVM6IQ17XH0S9S-JX%EI$HGL24EGYJ2SKISE02UQHPMYO9MN9JUHLKH.O93UQFJ6GL28LHXOAYJAPRAAUICO10W59UE1YHU-H4PIUF2VSJGV4J4LV/AYVG2$436D$X40YC2ATNS4Y6TKR2*G5C%CO8TJV4423 L0VV2 73-E3ND3DAJ-432$4U1JS.S./0LWTKD33236J3TA3E-4%:K7-SN2H N37J3JFTULJ5CBP:2C 2+*4HTC/2DBAJDAJCNB-43GV4MCTKD08DJHSI PISVDGZK4EC8.SX1LC8C8DJOMI$MI-N09*0245$UH8QIBD2GMJCKH9AO2R7./HBR6$LE KMDGKRFRSGHQED10H% 0R%0D 8YIPFHL:OTEGJUY25$0P/HX$4T0H//CI+CF/8-0LO1PX$4D4TVZ0D-4VZ0S1LZ0L:M623Q$B65VCNAIO38ZIIT-ROGV86O*$2/6PSQHV-P TN3H38EU2VME.3F$MM3WYC3A1N%IFBZV3P6$A9X81M:L-5TTPNFIVD6KL/O63UX0O7V9BYEB:IB BUAA9JM:ATN.AR81Y4GP21CPVY6P:KPG:LNLL%70/6MRVMT0LV0E7*EVLS2UIU6V2M3%26%Q3J*H:5L-28SXRWUH$LCQ/S3QTY5NG.8C5MN$V4-BXJMF5RG3U6-1RDVRWNY$3/ZB3MOQDWC*08M0AV5*/0QX4B-EF0MGH5X1FYHRGX8:+RY/EI%BQ95TC5*DW/ESR4S0:1ZF59*5GK1-OH4Z6-6FUOTN*H$38IPR4GT1$OE07B*SWKN*HF83N MO.CFOW3R%GB28Z$UOH7DROI9BW/CXPS0.PS USQE:LAVZP320%R902"
    return baseTestAT(barcode: barcode)
  }
  func baseTestAT(barcode: String) {
    var barcode = barcode
    // Remove HC1 header if any
    if (barcode.hasPrefix("HC1:")) {
      barcode = String(barcode.suffix(barcode.count-4))
    }

    guard
      let compressed = try? barcode.fromBase45()
    else {
      XCTAssert(false)
      return
    }

    let data = decompress(compressed)

    guard
      let kidBytes = CBOR.kid(from: data)
    else {
      XCTAssert(false)
      return
    }
    let kid = KID.stringFrom(kidBytes: kidBytes)
    guard
      let url = URL(string: "https://dgc.a-sit.at/ehn/cert/\(kid)")
    else {
      XCTAssert(false)
      return
    }
    let expectation = XCTestExpectation(description: "Download PubKey")
    URLSession.shared.dataTask(with: URLRequest(url: url)) { body, response, error in
      guard
        error == nil,
        let status = (response as? HTTPURLResponse)?.statusCode,
        200 == status,
        let body = body
      else {
        XCTAssert(false)
        return
      }
      let encodedCert = body.base64EncodedString()
      XCTAssert(KID.stringFrom(kidBytes: KID.from(encodedCert)) == kid)
      if COSE.verify(data, with: encodedCert) {
        expectation.fulfill()
      } else {
        XCTAssert(false)
      }
    }.resume()
    wait(for: [expectation], timeout: 15)
  }
}

/**

 Produces:

 All is well! Payload:  map([SwiftCBOR.CBOR.utf8String("foo"): SwiftCBOR.CBOR.utf8String("bar")])

 */
