import 'package:get/get.dart';
import 'package:ride_sharing_user_app/data/api_checker.dart';
import 'package:ride_sharing_user_app/features/home/domain/models/banner_model.dart';
import 'package:ride_sharing_user_app/features/home/domain/repositories/banner_repo.dart';

class BannerController extends GetxController implements GetxService {
  final BannerRepo bannerRepo;
  BannerController({required this.bannerRepo});

  int? _currentIndex = 0;
  int? get currentIndex => _currentIndex;
  bool isLoading = false;
  List<Banner>? bannerList;

  @override
  void onInit() {
    super.onInit();
    getBannerList();
  }

  Future<void> getBannerList() async {
    isLoading = true;
    update();
    Response? response = await bannerRepo.getBannerList();
    if (response != null && response.statusCode == 200) {
      bannerList = [];
      isLoading = false;
      if (response.body != null) {
        final bannerModel = BannerModel.fromJson(response.body);
        if (bannerModel.data != null) {
          bannerList!.addAll(bannerModel.data!);
        }
      }
    } else {
      isLoading = false;
      if (response != null) {
        ApiChecker.checkApi(response);
      }
    }
    update();
  }

  Future<void> updateBannerClickCount(String bannerId) async {
    Response? response = await bannerRepo.updateBannerClickCount(bannerId);
    if (response != null && response.statusCode == 200) {
      // Click registered successfully
    } else {
      if (response != null) {
        ApiChecker.checkApi(response);
      }
    }
    update();
  }

  void setCurrentIndex(int index, bool notify) {
    _currentIndex = index;
    if (notify) {
      update();
    }
  }
}
