import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';

Future<List<List<dynamic>>> loadCSV() async {
  final data = await rootBundle.loadString('assets/Crop_Calendar_Data.csv');
  List<List<dynamic>> csvData = const CsvToListConverter().convert(data);
  return csvData;
}

String getPlantingSeason(String plantName, List<List<dynamic>> csvData) {
  Set<String> uniqueSeasons = {};

  for (var row in csvData) {
    if (row[0].toString().toLowerCase() == plantName.toLowerCase()) {
      if (row[4] != null && row[4].toString().isNotEmpty) {
        String season = "Month ${row[4]}";
        uniqueSeasons.add(season);
      }
    }
  }

  return uniqueSeasons.isNotEmpty ? uniqueSeasons.join("\n") : "Plant not found";
}


class Season extends StatefulWidget {
  @override
  _Season createState() => _Season();
}

class _Season extends State<Season> {
  final TextEditingController _controller = TextEditingController();
  String season = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title:Text('Season to plant',style: TextStyle(
        color: Colors.white,
        fontSize: 30,
        fontWeight:FontWeight.bold,),),automaticallyImplyLeading: false,
        backgroundColor: Colors.blueGrey,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(labelText: 'Enter plant name',labelStyle: TextStyle(
                fontSize: 30,color: Colors.black),
                border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),),
                focusedBorder: OutlineInputBorder(  // Border when focused
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Colors.black,
                    width: 3,
                  ),
                )
              ),
              style: TextStyle(fontSize: 24),textAlign: TextAlign.center,
            ),
            ElevatedButton(
              onPressed: () async {
                var csvData = await loadCSV();
                setState(() {
                  season = getPlantingSeason(_controller.text, csvData);
                });
              },
              child: Text('Find Season' ,style: TextStyle(
                color: Colors.blueGrey,
                fontSize: 20,
              ),),
            ),
            SizedBox(height:10,),
            if (season.isNotEmpty) Text('Planting season:\n$season' ,style: TextStyle(
            color: Colors.black,
              fontSize: 20,),),
            SizedBox(height:40,),
            Opacity(
                opacity:0.7,
                child:Image.asset(
                  'assets/images/seasons.PNG',
                  height: 300,
                  fit: BoxFit.fill,
                ),
            ),
          ],
        ),
      ),
    );
  }
}
