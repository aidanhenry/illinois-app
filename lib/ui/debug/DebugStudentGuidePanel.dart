import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/StudentGuide.dart';
//import 'package:http/http.dart';
//import 'package:illinois/service/Network.dart';
//import 'package:flutter/services.dart' show rootBundle;
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/guide/StudentGuideCategoriesPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';
import 'package:illinois/utils/Utils.dart';

class DebugStudentGuidePanel extends StatefulWidget {
  DebugStudentGuidePanel();

  _DebugStudentGuidePanelState createState() => _DebugStudentGuidePanelState();
}

class _DebugStudentGuidePanelState extends State<DebugStudentGuidePanel> {

  TextEditingController _jsonController;
  bool _loadingJsonContent;

  @override
  void initState() {
    super.initState();
    _jsonController = TextEditingController();
    _loadingJsonContent = true;
    _loadJsonContent().then((String jsonContent) {
      setState(() {
        _loadingJsonContent = false;
      });
      _jsonController.text = jsonContent ?? '';
    });
  }

  @override
  void dispose() {
    super.dispose();
    _jsonController.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimpleHeaderBarWithBack(
        context: context,
        titleWidget: Text("Students Guide", style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: Styles().fontFamilies.extraBold),),
      ),
      body: SafeArea(child:
        Column(children: <Widget>[
          Expanded(child: 
            Padding(padding: EdgeInsets.all(16), child:
              _buildContent()
            ,),
          ),
        ],),
      ),
      backgroundColor: Styles().colors.background,
    );
  }

  Widget _buildContent() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: EdgeInsets.only(bottom: 4),
        child: Text("JSON", style: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 12, color: Styles().colors.fillColorPrimary),),
      ),
      Expanded(child:
        Stack(children: <Widget>[
          TextField(
            maxLines: 256,
            controller: _jsonController,
            decoration: InputDecoration(border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 1.0))),
            style: TextStyle(fontFamily: Styles().fontFamilies.regular, fontSize: 16, color: Styles().colors.textBackground,),
          ),
          Visibility(visible: (_loadingJsonContent == true),
            child: Align(alignment: Alignment.center,
              child: SizedBox(height: 32, width: 32,
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Styles().colors.fillColorSecondary), )
              ),
            ),
          ),
          Align(alignment: Alignment.topRight,
            child: GestureDetector(onTap: _onRefresh,
              child: Container(width: 36, height: 36,
                child: Align(alignment: Alignment.center,
                  child: Image.asset('images/icon-refresh.png'),
                ),
              ),
            ),
          ),
        ]),
      ),
      _buildPreview(),
    ],);
  }

  Widget _buildPreview() {
    return Padding(padding: EdgeInsets.only(top: 16), child: 
      Row(children: <Widget>[
        Expanded(child: Container(),),
        RoundedButton(label: "Preview",
          textColor: Styles().colors.fillColorPrimary,
          borderColor: Styles().colors.fillColorSecondary,
          backgroundColor: Styles().colors.white,
          fontFamily: Styles().fontFamilies.bold,
          fontSize: 16,
          padding: EdgeInsets.symmetric(horizontal: 32, ),
          borderWidth: 2,
          height: 42,
          onTap:() { _onPreview();  }
        ),
        Expanded(child: Container(),),
      ],),
    );
  }

  void _onRefresh() {
    if (_loadingJsonContent != true) {
      setState(() {
        _loadingJsonContent = true;
      });
      _jsonController.text = '';
      _loadJsonContent().then((String jsonContent) {
        setState(() {
          _loadingJsonContent = false;
        });
        _jsonController.text = jsonContent ?? '';
      });
    }
  }

  void _onPreview() {
    List<dynamic> jsonList = AppJson.decodeList(_jsonController.text);
    if (jsonList != null) {
      StudentGuide().contentList = jsonList;
      Navigator.push(context, CupertinoPageRoute(builder: (context) => StudentGuideCategoriesPanel()));
    }
    else {
      AppAlert.showDialogResult(context, "Failed to parse JSON");
    }
    
  }

  Future<String> _loadJsonContent() async {
    //Response response = await Network().get("https://rokwire-ios-beta.s3.us-east-2.amazonaws.com/Assets/student.guide.json");
    //String jsonContent = (response?.statusCode == 200) ? response?.body : null;
    
    //String jsonContent;
    //try { jsonContent = await rootBundle.loadString('assets/student.guide.json'); }
    //catch (e) { print(e?.toString()); }
    //return jsonContent;

    return AppJson.encode(StudentGuide().contentList, prettify: true);
  }
}

