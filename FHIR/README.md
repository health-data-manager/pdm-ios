#  FHIR

This frameworks serves to encapsulate the various FHIR parsing stuff. It is not a full FHIR library. It is intentionally a subset of the DSTU2 that's actually used. It's currently mostly intended as a place holder before moving to a "real" FHIR library.

Unfortunately, there are currently a few reasons why it's using custom code rather than a "real" library:

1. Since this is parsing FHIR DSTU2 documents, it needs to support FHIR DSTU2. The current Swift-FHIR that targets Swift 5 is using a draft release of FHIR 4.
2. This does not need to the full power of a "real" FHIR library. It needs enough to parse the documents coming from HealthKit and being looked at for the PDM. It does not need the ability to serialize new FHIR documents.
3. It will also need to be able to parse MCode documents that are an extension over the base FHIR.
4. There may be PDM-specific extension added in the future.
