import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/api_service.dart';

class BillScreen extends StatefulWidget {
  final String orderId;

  const BillScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  _BillScreenState createState() => _BillScreenState();
}

class _BillScreenState extends State<BillScreen> {
  bool _isLoading = false;
  List<dynamic> _orderItems = [];
  double _totalAmount = 0.0;
  String _orderStatus = '';
  String _notes = '';
  String _orderId = '';

  @override
  void initState() {
    super.initState();
    _orderId = widget.orderId;
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await ApiService().getOrder(_orderId);

      if (response['success'] == true && response['data'] != null) {
        final orderData = response['data'];
        setState(() {
          _orderItems = orderData['items'] ?? [];
          _totalAmount = (orderData['totalAmount'] ?? 0.0).toDouble();
          _orderStatus = orderData['status'] ?? '';
          _notes = orderData['notes'] ?? '';
        });
      }
    } catch (e) {
      print('Error fetching order details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading order details: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateOrder() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Format the order data
      Map<String, dynamic> orderData = {
        'items': _orderItems.map((item) {
          return {
            'product': item['product']['_id'],
            'quantity': item['quantity'],
            'price': item['price'],
            'measurements': item['measurements'],
          };
        }).toList(),
        'totalAmount': _totalAmount,
        'status': _orderStatus,
        'notes': _notes,
      };

      print('Sending order update with data: ${json.encode(orderData)}');

      final response = await ApiService().updateOrder(_orderId, orderData);

      if (response['success'] == true) {
        // Refresh the order data
        await _fetchOrderDetails();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order updated successfully')),
        );
      } else {
        throw Exception(response['error'] ?? 'Failed to update order');
      }
    } catch (e) {
      print('Error updating order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating order: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _isLoading ? null : _updateOrder,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(16),
              children: [
                // Order items list
                ..._orderItems
                    .map((item) => ListTile(
                          title: Text(item['product']['name'] ?? ''),
                          subtitle: Text('Quantity: ${item['quantity']}'),
                          trailing: Text('₹${item['price']}'),
                        ))
                    .toList(),

                Divider(),

                // Total amount
                ListTile(
                  title: Text('Total Amount'),
                  trailing: Text('₹$_totalAmount'),
                ),

                // Status
                ListTile(
                  title: Text('Status'),
                  trailing: Text(_orderStatus),
                ),

                // Notes
                if (_notes.isNotEmpty)
                  ListTile(
                    title: Text('Notes'),
                    subtitle: Text(_notes),
                  ),
              ],
            ),
    );
  }
}
