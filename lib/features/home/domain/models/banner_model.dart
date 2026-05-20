class BannerModel {
  int? totalSize;
  String? limit;
  String? offset;
  List<Banner>? data;

  BannerModel({this.totalSize, this.limit, this.offset, this.data});

  BannerModel.fromJson(Map<String, dynamic> json) {
    totalSize = json['total_size'];
    limit = json['limit'];
    offset = json['offset'];
    if (json['data'] != null) {
      data = <Banner>[];
      json['data'].forEach((v) {
        data!.add(Banner.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total_size'] = totalSize;
    data['limit'] = limit;
    data['offset'] = offset;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Banner {
  String? id;
  String? name;
  String? description;
  String? timePeriod;
  String? displayPosition;
  String? redirectLink;
  String? bannerGroup;
  String? startDate;
  String? endDate;
  String? image;
  String? userType;

  Banner({
    this.id,
    this.name,
    this.description,
    this.timePeriod,
    this.displayPosition,
    this.redirectLink,
    this.bannerGroup,
    this.startDate,
    this.endDate,
    this.image,
    this.userType,
  });

  Banner.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    name = json['name']?.toString();
    description = json['description']?.toString();
    timePeriod = json['time_period']?.toString();
    displayPosition = json['display_position']?.toString();
    redirectLink = json['redirect_link']?.toString();
    bannerGroup = json['banner_group']?.toString();
    startDate = json['start_date']?.toString();
    endDate = json['end_date']?.toString();
    image = json['image']?.toString();
    userType = (json['user_type'] ?? json['userType'])?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['description'] = description;
    data['time_period'] = timePeriod;
    data['display_position'] = displayPosition;
    data['redirect_link'] = redirectLink;
    data['banner_group'] = bannerGroup;
    data['start_date'] = startDate;
    data['end_date'] = endDate;
    data['image'] = image;
    data['user_type'] = userType;
    return data;
  }
}
