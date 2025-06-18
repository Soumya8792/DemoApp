class MessageModel {
  bool? success;
  String? app;
  int? totalMessages;
  List<Data>? data;

  MessageModel({this.success, this.app, this.totalMessages, this.data});

  MessageModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    app = json['app'];
    totalMessages = json['totalMessages'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(new Data.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    data['app'] = this.app;
    data['totalMessages'] = this.totalMessages;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Data {
  String? sId;
  String? userId;
  String? text;
  bool? isUser;
  String? timestamp;
  int? iV;
  List<ImgUrl>? imgUrl;

  Data(
      {this.sId,
      this.userId,
      this.text,
      this.isUser,
      this.timestamp,
      this.iV,
      this.imgUrl});

  Data.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    userId = json['userId'];
    text = json['text'];
    isUser = json['isUser'];
    timestamp = json['timestamp'];
    iV = json['__v'];
    if (json['imgUrl'] != null) {
      imgUrl = <ImgUrl>[];
      json['imgUrl'].forEach((v) {
        imgUrl!.add(new ImgUrl.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['userId'] = this.userId;
    data['text'] = this.text;
    data['isUser'] = this.isUser;
    data['timestamp'] = this.timestamp;
    data['__v'] = this.iV;
    if (this.imgUrl != null) {
      data['imgUrl'] = this.imgUrl!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ImgUrl {
  String? type;
  String? url;
  bool? isUser;

  ImgUrl({this.type, this.url, this.isUser});

  ImgUrl.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    url = json['url'];
    isUser = json['isUser'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['type'] = this.type;
    data['url'] = this.url;
    data['isUser'] = this.isUser;
    return data;
  }
}
