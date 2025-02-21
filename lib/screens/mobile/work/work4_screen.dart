

import 'dart:convert';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:king/constants/constants.dart';
import 'package:king/models/alias_enum.dart';
import 'package:king/screens/mobile/widgets/clock_widget.dart';
import 'package:king/screens/mobile/widgets/custom_captcha_widget.dart';
import 'package:king/screens/mobile/widgets/custom_keyboard.dart';
import 'package:king/screens/mobile/widgets/custom_textfield.dart';
import 'package:king/screens/settings/settings.dart';
import 'package:king/utils/utils.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../../../utils/dio_client.dart';


class WorkPage4 extends StatefulWidget {
  const WorkPage4({super.key});

  @override
  _WorkPage4State createState() => _WorkPage4State();
}



class _WorkPage4State extends State<WorkPage4> with AutomaticKeepAliveClientMixin {


  Uint8List? _imageBytes;
  final TextEditingController solveController = TextEditingController();
  bool _isLoading = false;


  @override
  Widget build(BuildContext context) {
    super.build(context);
    var width = MediaQuery.of(context).size.width;

    return Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            CustomImageWidget(imageBytes: _imageBytes,isFirst: false,),

            const SizedBox(height: 10),
            const StreamClockWidget(),
            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: (){
                      getCaptcha(int.parse(SettingsData.getUser1Id2));
                    },
                    child: _isLoading
                        ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.0,
                          ),
                        ),
                      ],
                    )
                        : const Text('معادلة'),
                  ),
                  SizedBox(
                    width: width * 0.15,
                    child: CustomTextField(
                      controller: solveController,
                      readOnly: true,
                      hint: 'الحل',
                      onChanged: (String? value) {  },
                    ),
                  ),
                  ElevatedButton(
                    onPressed: (){
                      getCaptcha(int.parse(SettingsData.getUser1Id2));
                    },
                    child: _isLoading
                        ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.0,
                          ),
                        ),
                      ],
                    )
                        : const Text('معادلة'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10,),

            CustomKeyboard(
              onBackspaceTap: (){
                if(solveController.text.isNotEmpty){
                  solveController.text = solveController.text.substring(0, solveController.text.length - 1);
                }
              },
              onKeyTap: (value){
                if(solveController.text.length < 4){
                  solveController.text = '${solveController.text}$value';
                }
              },
              onReserveTap: (){
                if(solveController.text.isNotEmpty){
                  reservePassport(int.parse(SettingsData.getUser1Id2), int.parse(solveController.text));
                  solveController.clear();
                }
              },
            ),
            const SizedBox(height: 10,),
          ],
        ),
    );
  }


  Future<bool> getCaptcha(int id) async {
    setState(() {
      _isLoading = true;
    });

    final captchaUrl = 'https://api.ecsc.gov.sy:8443/files/fs/captcha/$id';

    final Dio dio = DioClient.getDio();

    try {
      final response = await dio.get(captchaUrl, options: Utils.getOptions(AliasEnum.none,0));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        final String imageUrl = data['file'];
        // Utils.solveCaptcha({
        //   'img': 'data:image/jpg;base64,$imageUrl',
        // }).then((value){
        //   if(value != -1){
        //     reservePassport(id,value);
        //   }
        // });
        _imageBytes = base64Decode(imageUrl);
        setState(() {});

        return true;
      } else {
        final responseBody = json.decode(response.data);
        final message = responseBody['Message'];
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(
            message: message,
          ),
        );
        return false;
      }
    } on DioException catch (e) {
      String errorMessage = e.response?.data['Message'] ?? 'حدث خطأ اثناء طلب المعادلة في الصفحة 4';

      if(errorMessage.contains('تجاوزت') || errorMessage.contains('معالجة')){
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.info(
            message: errorMessage,
          ),
        );
        Utils.playAudio(AudioPlayer(),alertSound);
      }else{
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(
            message: errorMessage,
          ),
        );
      }
      return false;
    } catch (e) {
      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.error(
          message: 'An unexpected error occurred. Please try again.',
        ),
      );
      return false;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> reservePassport(int id, int captcha) async {
    final reserveUrl = 'https://api.ecsc.gov.sy:8443/rs/reserve?id=$id&captcha=$captcha';
    final Dio dio = DioClient.getDio();

    for(int i = 0;i < 5;i++){
      try {
        final response = await dio.get(reserveUrl, options: Utils.getOptions(AliasEnum.reserve,0));

        if (response.statusCode == 200) {
          showTopSnackBar(
            Overlay.of(context),
            const CustomSnackBar.success(
              message: "تم تثبيت المعاملة بنجاح",
            ),
          );
          break;
        }

      } on DioException catch (e) {
        String errorMessage = e.response?.data['Message'] ?? 'An unexpected error occurred.';

        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(
            message: errorMessage,
          ),
        );
        if(errorMessage.contains('نأسف') || errorMessage.contains('النتيجة')){
          break;
        }
      } catch (e) {
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.error(
            message: 'An unexpected error occurred. Please try again.',
          ),
        );
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  @override
  bool get wantKeepAlive => true;

}
