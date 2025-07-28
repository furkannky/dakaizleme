class Project {
  final String id;
  final String name;
  final String mdpName;
  final String supportType;
  final String supportedField;
  final int mdpYear;
  final String beneficiaryName;
  final String referenceNo;
  final String status;
  final String naceActivitySection;
  final String? province;
  final String? district;
  final double technicalSupportCost;
  final double finalBudget;
  final double finalGrant;
  final DateTime contractSigningDate;
  final DateTime startDate;
  final DateTime endDate;
  final double deflatorValue2025Budget;
  final double deflatorValue2025Grant;
  final double latitude;
  final double longitude;
  final String? imageUrl;

  Project({
    required this.id,
    required this.name,
    required this.mdpName,
    required this.supportType,
    required this.supportedField,
    required this.mdpYear,
    required this.beneficiaryName,
    required this.referenceNo,
    required this.status,
    required this.naceActivitySection,
    this.province,
    this.district,
    required this.technicalSupportCost,
    required this.finalBudget,
    required this.finalGrant,
    required this.contractSigningDate,
    required this.startDate,
    required this.endDate,
    required this.deflatorValue2025Budget,
    required this.deflatorValue2025Grant,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
  });

  // Firestore'dan veri okumak için
  factory Project.fromFirestore(Map<String, dynamic> firestore, String id) {
    return Project(
      id: id,
      name: firestore['name'] ?? '',
      mdpName: firestore['mdpName'] ?? '',
      supportType: firestore['supportType'] ?? '',
      supportedField: firestore['supportedField'] ?? '',
      mdpYear: firestore['mdpYear'] ?? 0,
      beneficiaryName: firestore['beneficiaryName'] ?? '',
      referenceNo: firestore['referenceNo'] ?? '',
      status: firestore['status'] ?? '',
      naceActivitySection: firestore['naceActivitySection'] ?? '',
      province: firestore['province'],
      district: firestore['district'],
      technicalSupportCost: firestore['technicalSupportCost']?.toDouble() ?? 0.0,
      finalBudget: firestore['finalBudget']?.toDouble() ?? 0.0,
      finalGrant: firestore['finalGrant']?.toDouble() ?? 0.0,
      contractSigningDate: firestore['contractSigningDate']?.toDate() ?? DateTime.now(),
      startDate: firestore['startDate']?.toDate() ?? DateTime.now(),
      endDate: firestore['endDate']?.toDate() ?? DateTime.now(),
      deflatorValue2025Budget: firestore['deflatorValue2025Budget']?.toDouble() ?? 0.0,
      deflatorValue2025Grant: firestore['deflatorValue2025Grant']?.toDouble() ?? 0.0,
      latitude: firestore['latitude']?.toDouble() ?? 0.0,
      longitude: firestore['longitude']?.toDouble() ?? 0.0,
      imageUrl: firestore['imageUrl'],
    );
  }

  // Firestore'a veri yazmak için
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'mdpName': mdpName,
      'supportType': supportType,
      'supportedField': supportedField,
      'mdpYear': mdpYear,
      'beneficiaryName': beneficiaryName,
      'referenceNo': referenceNo,
      'status': status,
      'naceActivitySection': naceActivitySection,
      'province': province,
      'district': district,
      'technicalSupportCost': technicalSupportCost,
      'finalBudget': finalBudget,
      'finalGrant': finalGrant,
      'contractSigningDate': contractSigningDate,
      'startDate': startDate,
      'endDate': endDate,
      'deflatorValue2025Budget': deflatorValue2025Budget,
      'deflatorValue2025Grant': deflatorValue2025Grant,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
    };
  }
}