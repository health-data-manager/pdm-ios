//
//  AllergyIntolerance.swift
//  myPHR
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import Foundation

public class AllergyIntolerance : FHIRResource {
    public static let resourceType = "AllergyIntolerance"
    public var id: Identifier?
    public var onset: Date?
    public var recordedDate: DateTime?
    //public var recorder: Reference(Practitioner | Patient)    Who recorded the sensitivity
    //public var patient: Reference(Patient)    Who the sensitivity is for
    //public var reporter: Reference(Patient | RelatedPerson | Practitioner)    Source of the information about the allergy
    public var substance: CodeableConcept?
    public var status: StatusCode?
    public var criticality: CriticalityCode?
    public var type: TypeCode?
    public var category: CategoryCode?
    public var lastOccurence: Date?
    public var note: Annotation?
    public var reaction: [Reaction]?

    override init(fromJSON json: [String : Any]) {
        super.init(fromJSON: json)
        if let recordedDate = json["recordedDate"] as? String {
            self.recordedDate = DateTime(recordedDate)
        }
        if let substance = json["substance"] as? [String : Any] {
            self.substance = CodeableConcept(fromJSON: substance)
        }
        if let status = json["status"] as? String {
            self.status = StatusCode(rawValue: status)
        }
        if let criticality = json["criticality"] as? String {
            self.criticality = CriticalityCode(rawValue: criticality)
        }
        if let type = json["type"] as? String {
            self.type = TypeCode(rawValue: type)
        }
        if let category = json["category"] as? String {
            self.category = CategoryCode(rawValue: category)
        }
        if let reactions = json["reaction"] as? [Any] {
            var parsedReactions = [Reaction]()
            for reactionInstance in reactions {
                if let reactionJSON = reactionInstance as? [String : Any] {
                    parsedReactions.append(Reaction(fromJSON: reactionJSON))
                }
            }
            self.reaction = parsedReactions
        }
    }

    public enum StatusCode: String, CaseIterable {
        case active
        case unconfirmed
        case confirmed
        case inactive
        case resolved
        case refuted
        case enteredInError = "entered-in-error"
    }
    public enum CriticalityCode: String, CaseIterable {
        case lowRisk = "CRITL"
        case highRisk = "CRITH"
        case unableToDetermine = "CRITU"
    }
    public enum TypeCode: String, CaseIterable {
        case allergy
        case intolerance
    }
    public enum CategoryCode: String, CaseIterable {
        case food
        case medication
        case environment
        case other
    }
}

public class Reaction {
    public var substance: CodeableConcept?
    public var certainty: CertaintyCode?
    public var manifestation: [CodeableConcept]?
    public var description: String?
    public var onset: Date?
    public var severity: SeverityCode?
    public var exposureRoute: CodeableConcept?
    public var note: Annotation?

    public init() { }
    public init(fromJSON json: [String: Any]) {
        if let substance = json["substance"] as? [String: Any] {
            self.substance = CodeableConcept(fromJSON: substance)
        }
        if let certainty = json["certainty"] as? String {
            self.certainty = CertaintyCode(rawValue: certainty)
        }
        if let manifestation = json["manifestation"] as? [Any] {
            var parsedManifestations = [CodeableConcept]()
            for manifestationInstance in manifestation {
                if let manifestJSON = manifestationInstance as? [String : Any] {
                    parsedManifestations.append(CodeableConcept(fromJSON: manifestJSON))
                }
            }
            self.manifestation = parsedManifestations
        }
        if let description = json["description"] as? String {
            self.description = description
        }
        if let severity = json["severity"] as? String {
            self.severity = SeverityCode(rawValue: severity)
        }
        if let exposureRoute = json["exposureRoute"] as? [String: Any] {
            self.exposureRoute = CodeableConcept(fromJSON: exposureRoute)
        }
        if let note = json["note"] as? [String: Any] {
            self.note = Annotation(fromJSON: note)
        }
    }
    public enum CertaintyCode: String, CaseIterable {
        case unlikely
        case likely
        case confirmed
    }
    public enum SeverityCode: String, CaseIterable {
        case mild
        case moderate
        case severe
    }
}
