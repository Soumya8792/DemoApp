class UpdateMessageModel {
  bool? success;
  Message? message;

  UpdateMessageModel({this.success, this.message});

  UpdateMessageModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message =
        json['message'] != null ? new Message.fromJson(json['message']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.message != null) {
      data['message'] = this.message!.toJson();
    }
    return data;
  }
}

class Message {
  String? sId;
  String? userId;
  String? text;
  bool? isUser;
  Image? image;
  Image? videoUrl;
  MultiImageUrl? multiImageUrl;
  Image? enhancedImageUrl;
  String? timestamp;
  int? iV;

  Message(
      {this.sId,
      this.userId,
      this.text,
      this.isUser,
      this.image,
      this.videoUrl,
      this.multiImageUrl,
      this.enhancedImageUrl,
      this.timestamp,
      this.iV});

  Message.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    userId = json['userId'];
    text = json['text'];
    isUser = json['isUser'];
    image = json['image'] != null ? new Image.fromJson(json['image']) : null;
    videoUrl =
        json['videoUrl'] != null ? new Image.fromJson(json['videoUrl']) : null;
    multiImageUrl = json['multiImageUrl'] != null
        ? new MultiImageUrl.fromJson(json['multiImageUrl'])
        : null;
    enhancedImageUrl = json['enhancedImageUrl'] != null
        ? new Image.fromJson(json['enhancedImageUrl'])
        : null;
    timestamp = json['timestamp'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['userId'] = this.userId;
    data['text'] = this.text;
    data['isUser'] = this.isUser;
    if (this.image != null) {
      data['image'] = this.image!.toJson();
    }
    if (this.videoUrl != null) {
      data['videoUrl'] = this.videoUrl!.toJson();
    }
    if (this.multiImageUrl != null) {
      data['multiImageUrl'] = this.multiImageUrl!.toJson();
    }
    if (this.enhancedImageUrl != null) {
      data['enhancedImageUrl'] = this.enhancedImageUrl!.toJson();
    }
    data['timestamp'] = this.timestamp;
    data['__v'] = this.iV;
    return data;
  }
}

class Image {
  String? url;
  bool? isUser;

  Image({this.url, this.isUser});

  Image.fromJson(Map<String, dynamic> json) {
    url = json['url'];
    isUser = json['isUser'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['url'] = this.url;
    data['isUser'] = this.isUser;
    return data;
  }
}

class MultiImageUrl {
  List<String>? urls;
  bool? isUser;

  MultiImageUrl({this.urls, this.isUser});

  MultiImageUrl.fromJson(Map<String, dynamic> json) {
    urls = json['urls'].cast<String>();
    isUser = json['isUser'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['urls'] = this.urls;
    data['isUser'] = this.isUser;
    return data;
  }
}
