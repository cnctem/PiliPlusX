class DynReserveData {
  int? finalBtnStatus;
  int? reserveUpdate;
  String? descUpdate;

  DynReserveData({
    this.finalBtnStatus,
    this.reserveUpdate,
    this.descUpdate,
  });

  factory DynReserveData.fromJson(Map<String, dynamic> json) => DynReserveData(
    finalBtnStatus: json['final_btn_status'] as int?,
    reserveUpdate: json['reserve_update'] as int?,
    descUpdate: json['desc_update'] as String?,
  );
}
