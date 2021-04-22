/*-
 * ---license-start
 * eu-digital-green-certificates / dgca-verifier-app-web
 * ---
 * Copyright (C) 2021 T-Systems International GmbH and all other contributors
 * ---
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ---license-end
 */
//
//  EuDgcSchema.swift
//  PatientScannerDemo
//
//  Created by Yannick Spreen on 4/20/21.
//

import Foundation

let EU_DGC_SCHEMA_V1 = """
{
    "$schema": "http://json-schema.org/draft/2020-12/schema#",
    "$id": "https://github.com/ehn-digital-green-development/hcert-schema/eu_dgc_v1",
    "title": "Digital Green Certificate",
    "description": "Proof of vaccination, test results or recovery according to EU eHN, version 1.0, including certificate metadata; According to 1) REGULATION OF THE EUROPEAN PARLIAMENT AND OF THE COUNCIL on a framework for the issuance, verification and acceptance of interoperable certificates on vaccination, testing and recovery to facilitate free movement during the COVID-19 pandemic (Digital Green Certificate) - https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX%3A52021PC0130 2) Document \\"Value Sets for the digital green certificate as stated in the Annex ...\\", abbr. \\"VS-2021-04-14\\" - https://webgate.ec.europa.eu/fpfis/wikis/x/05PuKg 3) Guidelines on verifiable vaccination certificates - basic interoperability elements - Release 2 - 2021-03-12, abbr. \\"guidelines\\"",
    "type": "object",
    "required": [
        "v",
        "dgcid",
        "sub"
    ],
    "properties": {
        "v": {
            "title": "Schema version",
            "description": "Version of the schema, according to Semantic versioning (ISO, https://semver.org/ version 2.0.0 or newer) (viz. guidelines)",
            "type": "string",
            "example": "1.0.0"
        },
        "dgcid": {
            "title": "Identifier",
            "description": "Unique identifier of the DGC (initially called UVCI (V for vaccination), later renamed to DGCI), format and composizion viz. guidelines",
            "type": "string",
            "example": "01AT42196560275230427402470256520250042"
        },
        "sub": {
            "description": "Subject",
            "type": "object",
            "required": [
                "gn",
                "dob"
            ],
            "properties": {
                "gn": {
                    "title": "Given name",
                    "description": "The given name(s) of the person addressed in the certificate",
                    "type": "string",
                    "example": "T\\u00f6lvan"
                },
                "fn": {
                    "title": "Family name",
                    "description": "The family name(s) of the person addressed in the certificate",
                    "type": "string",
                    "example": "T\\u00f6lvansson"
                },
                "gnt": {
                    "title": "Given name (transliterated)",
                    "description": "The given name(s) of the person addressed in the certificate transliterated into the OCR-B Characters from ISO 1073-2 according to the ICAO Doc 9303 part 3.",
                    "type": "string",
                    "example": "Toelvan"
                },
                "fnt": {
                    "title": "Family name (transliterated)",
                    "description": "The family name(s) of the person addressed in the certificate transliterated into the OCR-B Characters from ISO 1073-2 according to the ICAO Doc 9303 part 3.",
                    "type": "string",
                    "example": "Toelvansson"
                },
                "id": {
                    "title": "Person identifiers",
                    "description": "Identifiers of the vaccinated person, according to the policies applicable in each country",
                    "type": "array",
                    "items": {
                        "type": "object",
                        "required": [
                            "t",
                            "c",
                            "i"
                        ],
                        "properties": {
                            "t": {
                                "title": "Identifier type",
                                "description": "The type of identifier (viz. VS-2021-04-08) PP = Passport Number NN = National Person Identifier (country specified in the 'c' parameter) CZ = Citizenship Card Number HC = Health Card Number",
                                "type": "string",
                                "enum": [
                                    "PP",
                                    "NN",
                                    "CZ",
                                    "HC"
                                ],
                                "example": "NN"
                            },
                            "c": {
                                "title": "Country",
                                "description": "Issuing country (ISO 3166-1 alpha-2 country code) of identifier",
                                "type": "string",
                                "example": "SE"
                            },
                            "i": {
                                "title": "Identifier number or string",
                                "type": "string",
                                "example": "121212-1212"
                            }
                        }
                    }
                },
                "dob": {
                    "title": "Date of birth",
                    "description": "The date of birth of the person addressed in the certificate",
                    "type": "string",
                    "format": "date",
                    "example": "2012-12-12"
                }
            }
        },
        "vac": {
            "description": "Vaccination/prophylaxis information",
            "type": "array",
            "items": {
                "type": "object",
                "required": [
                    "dis",
                    "vap",
                    "mep",
                    "aut",
                    "seq",
                    "tot",
                    "dat",
                    "cou"
                ],
                "properties": {
                    "dis": {
                        "title": "Disease",
                        "description": "Disease or agent targeted (viz. VS-2021-04-14)",
                        "type": "string",
                        "example": "840539006"
                    },
                    "vap": {
                        "title": "Vaccine/prophylaxis",
                        "description": "Generic description of the vaccine/prophylaxis or its component(s), (viz. VS-2021-04-14)",
                        "type": "string",
                        "example": "1119305005"
                    },
                    "mep": {
                        "title": "Vaccine medicinal product",
                        "description": "Code of the medicinal product (viz. VS-2021-04-14)",
                        "type": "string",
                        "example": "EU/1/20/1528"
                    },
                    "aut": {
                        "title": "Vaccine marketing authorization holder or Vaccine manufacturer",
                        "description": "Code as defined in EMA SPOR - Organisations Management System (viz. VS-2021-04-14)",
                        "type": "string",
                        "example": "ORG-100030215"
                    },
                    "seq": {
                        "title": "Dose sequence number",
                        "description": "Number of dose administered in a cycle  (viz. VS-2021-04-14)",
                        "type": "integer",
                        "minimum": 0,
                        "example": 1
                    },
                    "tot": {
                        "title": "Total number of doses",
                        "description": "Number of expected doses for a complete cycle (specific for a person at the time of administration) (viz. VS-2021-04-14)",
                        "type": "integer",
                        "minimum": 0,
                        "example": 2
                    },
                    "dat": {
                        "title": "Date of vaccination",
                        "description": "The date of the vaccination event",
                        "type": "string",
                        "format": "date",
                        "example": "2021-02-20"
                    },
                    "cou": {
                        "title": "Country",
                        "description": "Country (member state) of vaccination (ISO 3166-1 alpha-2 Country Code) (viz. VS-2021-04-14)",
                        "type": "string",
                        "example": "SE"
                    },
                    "lot": {
                        "title": "Batch/lot number",
                        "description": "A distinctive combination of numbers and/or letters which specifically identifies a batch, optional",
                        "type": "string"
                    },
                    "adm": {
                        "title": "Administering centre",
                        "description": "Name/code of administering centre or a health authority responsible for the vaccination event, optional",
                        "type": "string",
                        "example": "Region Halland"
                    }
                }
            }
        },
        "tst": {
            "description": "Test result statement",
            "type": "array",
            "items": {
                "type": "object",
                "required": [
                    "dis",
                    "typ",
                    "dts",
                    "dtr",
                    "res",
                    "fac",
                    "cou"
                ],
                "properties": {
                    "dis": {
                        "title": "Disease",
                        "description": "Disease or agent targeted (viz. VS-2021-04-14)",
                        "type": "string",
                        "example": "840539006"
                    },
                    "typ": {
                        "title": "Type of test",
                        "description": "Code of the type of test that was conducted",
                        "type": "string",
                        "example": "LP6464-4"
                    },
                    "tma": {
                        "title": "Manufacturer and test name",
                        "description": "Manufacturer and commercial name of the test used (optional for NAAT test) (viz. VS-2021-04-14)",
                        "type": "string",
                        "example": "tbd"
                    },
                    "ori": {
                        "title": "Sample origin",
                        "description": "Origin of sample that was taken (e.g. nasopharyngeal swab, oropharyngeal swab etc.) (viz. VS-2021-04-14) optional",
                        "type": "string",
                        "example": "258500001"
                    },
                    "dts": {
                        "title": "Date and time sample",
                        "description": "Date and time when the sample for the test was collected (seconds since epoch)",
                        "type": "integer",
                        "minimum": 0,
                        "example": 441759600
                    },
                    "dtr": {
                        "title": "Date and time test result",
                        "description": "Date and time when the test result was produced (seconds since epoch)",
                        "type": "integer",
                        "minimum": 0,
                        "example": 441759600
                    },
                    "res": {
                        "title": "Result of test",
                        "description": "Result of the test according to SNOMED CT (viz. VS-2021-04-14)",
                        "type": "string",
                        "example": "1240591000000104"
                    },
                    "fac": {
                        "title": "Testing centre or facility",
                        "description": "Name/code of testing centre, facility or a health authority responsible for the testing event.",
                        "type": "string",
                        "example": "tbd"
                    },
                    "cou": {
                        "title": "Country",
                        "description": "Country (member state) of test (ISO 3166-1 alpha-2 Country Code)",
                        "type": "string",
                        "example": "SE"
                    }
                }
            }
        },
        "rec": {
            "description": "Recovery statement",
            "type": "array",
            "items": {
                "type": "object",
                "required": [
                    "dis",
                    "dat",
                    "cou"
                ],
                "properties": {
                    "dis": {
                        "title": "Disease",
                        "description": "Disease or agent the citizen has recovered from",
                        "type": "string",
                        "example": "840539006"
                    },
                    "dat": {
                        "title": "Date of first positive test result",
                        "description": "The date when the sample for the test was collected that led to a positive test result",
                        "type": "string",
                        "format": "date",
                        "example": "2021-02-20"
                    },
                    "cou": {
                        "title": "Country of test",
                        "description": "Country (member state) in which the first positive test was performed (ISO 3166-1 alpha-2 Country Code)",
                        "type": "string",
                        "example": "SE"
                    }
                }
            }
        }
    }
}
"""
