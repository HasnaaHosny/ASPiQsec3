// ../Report/progress_bar.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ProgressBarCard extends StatefulWidget {
  final String title;
  final String description;
  final String endpoint;
  final VoidCallback? onTap;

  const ProgressBarCard({
    Key? key,
    required this.title,
    required this.description,
    required this.endpoint,
    this.onTap,
  }) : super(key: key);

  @override
  _ProgressBarCardState createState() => _ProgressBarCardState();
}

class _ProgressBarCardState extends State<ProgressBarCard> {
  double _progress = 0.0;
  bool _isLoading = true;
  String? _jwtToken;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchProgress();
  }

  Future<void> _loadTokenAndFetchProgress() async {
    final prefs = await SharedPreferences.getInstance();
    _jwtToken = prefs.getString('auth_token');
    if (_jwtToken == null) {
      print('JWT token not found in SharedPreferences.');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }
    _fetchProgress();
  }

  Future<void> _fetchProgress() async {
    if (_jwtToken == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(widget.endpoint),
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer $_jwtToken',
        },
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['progress'] is num) {
          setState(() {
            _progress = (data['progress'] as num).toDouble() / 100.0;
            _isLoading = false;
          });
        } else {
          print('Progress data is not in the expected format: $data');
          setState(() {
            _isLoading = false;
            _progress = 0.0;
          });
        }
      } else {
        print('Failed to load progress: ${response.statusCode}, Body: ${response.body}');
        setState(() {
          _isLoading = false;
          _progress = 0.0;
        });
      }
    } catch (e) {
      if (!mounted) return;
      print('Error fetching progress for ${widget.title}: $e');
      setState(() {
        _isLoading = false;
        _progress = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF2C73D9);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      elevation: 2.0,
      color: const Color.fromARGB(255, 249, 252, 255), 
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          widget.description,
                          style: TextStyle(
                            fontSize: 14.0,
                            color: Colors.grey[700],
                            fontFamily: 'Cairo',
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 18.0,
                      color: primaryBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              _isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: primaryBlue),
                      ),
                    )
                  : Row( // النص وشريط التقدم في صف واحد
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded( // شريط التقدم يأخذ المساحة المتاحة
                          child: LinearProgressIndicator(
                            value: _progress,
                            backgroundColor: Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation<Color>(primaryBlue),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8.0), // مسافة بين الشريط والنص
                        Text( // النص على يسار الشريط (بسبب RTL الافتراضي في التطبيق)
                          '${(_progress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Colors.grey[700],
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}