//
//  EHNTests.swift
//  EHNTests
//
//  Created by Dirk-Willem van Gulik on 01/04/2021.
//

@testable import PatientScannerDemo
import XCTest


class EHNTests: XCTestCase {
  func testCoseEcdsa() throws {
    var barcode = "HC1NCFY70R30FFWTWGSLKC 4O992$V M63TMF2V*D9LPC.3EHPCGEC27B72VF/347O4-M6Y9M6FOYG4ILDEI8GR3ZI$15MABL:E9CVBGEEWRMLE C39S0/ANZ52T82Z-73D63P1U 1$PKC 72H2XX09WDH889V5"

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

    // Remove HC1 header if any
    if (barcode.hasPrefix("HC1")) {
      barcode = String(barcode.suffix(barcode.count-3))
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
    let barcode = "HC1NCFI.L3B6AP2YQ2%MNBCHC51/CAOZDL+OL7S99U60SVOGSHD%24R4PCTH7Y9KL6EVJBIMBL364D X1KKLZ*I9K4RLDR7B011EROZS6022WR5VX4QG9W72HWCC12B:TWZG.%N8GWBCOV0O%5F9U7H 8P4L.%2/:6TXB/-J6ZJ.*QYIBYSD6/T.6RDMMK0PX6HTPO1REO*CWMFG5CJ38+FBS+8DB9*2FFP9Z8HEM137CRBQ.893$I.R7 DRFOVMUQRVDP4IU613/G-0LZ:43+MM:QO.CQPJU21-7PJ*L/*DVLO:Q5G-7%WF4ZO*JJR:KH+O1707M6.73VXG0+0050+IMIFH:3V+DL3JK/21/LEI$T5TUT8P:40P10AXGBRS%-GZS8TGF-IT3-HU2SVJUAVG%AGO98R00Y.QT23DVP0TB*-J6YJP 8TU9U/OJSQGGMK+K3MH IR U7H%9/UU07AGEWMVTOBAYIV4SPGC2Y5FJJ67I4/J4FXM3GP:SAOZQJPL%WGP4BT59Q8K5MB*M44%K9JTWB9K+LS-2I9ST+3J%0X%1YGN0E0KL3/FHTZHEF9WIC4Q1HVK74L186BWT9+TJR7C2M%9JXN8S%0PVU8GFBET%0PG RR1KD2F11G-CW8A4124N9VN-T-:292AX*B%ER*$12-O:6K:/N$ 7IYFFXQ/5F NC49M/W5501B2OKU7E:NHMM8SETWUK*I$JR"
    return baseTestAT(barcode: barcode)
  }
  func testCoseRsaAT() throws {
    let barcode = "HC1NCFI.LUZB.P2YQ2E R002$DLTLIYXM/+0JNEAFUP.CV5GKCL /A0SQT/O8ZA85D0IJ$5D4.J+MR8-EGK6DM1R58V1ERUCWM4.E4ZM4$WG  O E6KX9$KHCQMFE0B$KPKA*A2+ELQ*5ZQE/*1ZMSM5S.:KGQ33LQOWN67QW68LXM867D6837QCWEU*E*OKZCJPSCPIM1:Q83FBODLRD/W8K$E4 SG4P2JM6GCMU9FFSZAKNJH6ZNZVSWU78MHB4TO5J0N51U2F:17AB8O0*N0CQSA-9VIN904*STT$6R1LLXDT8J1ZN4I4368L02N72ZMGV496.0NO3OQCPFVF+C$BKQH1$+8L:AAEGRIB548B68D/3-ZTZ.JNM84E0F59$N6DY2*6FACA448900U42ZEMMO7-LO.45*IMXYIODF:82RN4L8Q%20HDJ-YCHIA1YT87A2/C1NO1F6DPCLCK9+BDXEEK23JH0/I8XJQEQ1T8BQ5GNDRFPQKKV6WT$A+98TIOUSAFA0J8OMY87$P-LESPS1KO+:O%HOY*C8XH4ZE7D16QR WNN$EP:U7E2HTLS023X0GJBW887LCKVHDGJ+Q88I0A73$H6R30XYH-LDC$4+24*JSE*H98A471BJ3:R0LU3MZA+ 4/GMZ9J D4E7L.TI$L8L:TN4G2S552748V$%D0CPH9RJ-7Z4AXFN*SS/ZC44O3P5%%AE936OUSR1H7WP%CP8KQUCY9I%A5FDBV+0A%HPVP5SKP9TKAFKT9FYROAABDBEHVQ9317O0D7MS5Z.Q2+K2.1RGGS3B5OTO2ROD60Z6LE98E94TV09JXM395VA0N.98EP3*4E5SHA7I96Q70UF74SPSIJI.BUHQJ$:K$9M51H9Z6RPHR.K-XT855UJJZC8C*MSITGMRE%O+:JQXV$LS7SJ1:DE LCX7RP7T JH4RR-NK.PASIWKA8J5Z1NA*BE7KFTJXO4BM5QVF.S0-5CG8KQWB8RCA1VP*1Q.ELZ1Q21G.JEGLOFH1:FR09$SCY/OGBU1QIE/2 9SK3"
    return baseTestAT(barcode: barcode)
  }
  func baseTestAT(barcode: String) {
    var barcode = barcode
    // Remove HC1 header if any
    if (barcode.hasPrefix("HC1")) {
      barcode = String(barcode.suffix(barcode.count-3))
    }

    guard
      let compressed = try? barcode.fromBase45()
    else {
      XCTAssert(false)
      return
    }

    let data = decompress(compressed)

    guard
      let kidBytes = CBOR.kid(from: data),
      let kid = String(data: Data(kidBytes), encoding: .utf8),
      let url = URL(string: "https://dev.a-sit.at/certservice/cert/\(kid)")
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
