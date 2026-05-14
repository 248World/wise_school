import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/notification_service.dart';

class FeesScreen extends StatefulWidget {
  final String role;

  const FeesScreen({
    super.key,
    this.role = 'Parent',
  });

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;

  List<Map<String, dynamic>> fees = [];
  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> paymentConfirmations = [];

  String currentRole = 'Parent';
  String currentUserId = '';
  String currentUserName = '';

  String selectedStudentId = '';
  String selectedStudentName = '';
  String selectedClassId = '';
  String selectedClassName = '';
  String selectedStatus = 'Unpaid';

  Map<String, dynamic>? bankDetails;

  final titleController = TextEditingController();
  final amountController = TextEditingController();
  final noteController = TextEditingController();

  final bankNameController = TextEditingController();
  final accountNameController = TextEditingController();
  final accountNumberController = TextEditingController();
  final ibanController = TextEditingController();
  final ribController = TextEditingController();
  final bankNoteController = TextEditingController();

  final paymentAmountController = TextEditingController();
  final paymentMethodController = TextEditingController();
  final transactionReferenceController = TextEditingController();
  final paymentMessageController = TextEditingController();

  DateTime selectedPaymentDate = DateTime.now();

  final List<String> statuses = [
    'Unpaid',
    'Partially Paid',
    'Paid',
  ];

  bool get canCreateFee {
    return currentRole == 'Admin';
  }

  bool get isParent {
    return currentRole == 'Parent';
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      loadInitialData();
    });
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    noteController.dispose();

    bankNameController.dispose();
    accountNameController.dispose();
    accountNumberController.dispose();
    ibanController.dispose();
    ribController.dispose();
    bankNoteController.dispose();

    paymentAmountController.dispose();
    paymentMethodController.dispose();
    transactionReferenceController.dispose();
    paymentMessageController.dispose();

    super.dispose();
  }

  Future<void> loadInitialData() async {
    try {
      final authProvider = context.read<AuthProvider>();

      currentRole = widget.role;
      currentUserId = authProvider.userId ?? '';
      currentUserName = authProvider.fullName ?? currentRole;

      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      await loadBankDetails();

      if (currentRole == 'Admin') {
        await loadStudents();
        await loadAllFees();
        await loadAllPaymentConfirmations();
      } else if (currentRole == 'Parent') {
        await loadParentFees();
        await loadParentPaymentConfirmations();
      } else if (currentRole == 'Student') {
        await loadStudentFees();
      } else {
        await loadAllFees();
      }

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString().replaceAll('Exception: ', '');
        isLoading = false;
      });
    }
  }

  Future<void> loadBankDetails() async {
    final doc =
        await firestore.collection('school_settings').doc('bank_details').get();

    if (!doc.exists) {
      bankDetails = null;
      return;
    }

    final data = doc.data();

    bankDetails = {
      'bankName': data?['bankName'] ?? '',
      'accountName': data?['accountName'] ?? '',
      'accountNumber': data?['accountNumber'] ?? '',
      'iban': data?['iban'] ?? '',
      'rib': data?['rib'] ?? '',
      'note': data?['note'] ?? '',
      'updatedAt': data?['updatedAt'],
    };
  }

  Future<void> saveBankDetails() async {
    final bankName = bankNameController.text.trim();
    final accountName = accountNameController.text.trim();
    final accountNumber = accountNumberController.text.trim();
    final iban = ibanController.text.trim();
    final rib = ribController.text.trim();
    final note = bankNoteController.text.trim();

    if (bankName.isEmpty) {
      showSnackBar('Please enter bank name');
      return;
    }

    if (accountName.isEmpty) {
      showSnackBar('Please enter account name');
      return;
    }

    if (accountNumber.isEmpty && iban.isEmpty && rib.isEmpty) {
      showSnackBar('Please enter account number, IBAN, or RIB');
      return;
    }

    try {
      setState(() {
        isSaving = true;
      });

      await firestore.collection('school_settings').doc('bank_details').set({
        'bankName': bankName,
        'accountName': accountName,
        'accountNumber': accountNumber,
        'iban': iban,
        'rib': rib,
        'note': note,
        'updatedBy': currentUserId,
        'updatedByName': currentUserName,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.pop(context);

      await loadInitialData();

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      showSnackBar('Bank details saved successfully');
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> loadStudents() async {
    final snapshot = await firestore
        .collection('users')
        .where('role', isEqualTo: 'Student')
        .where('isActive', isEqualTo: true)
        .get();

    students = snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'fullName': data['fullName'] ?? '',
        'email': data['email'] ?? '',
        'classId': data['classId'] ?? '',
        'className': data['className'] ?? '',
        'parentId': data['parentId'] ?? '',
        'parentName': data['parentName'] ?? '',
      };
    }).toList();

    students.sort((a, b) {
      final nameA = (a['fullName'] ?? '').toString();
      final nameB = (b['fullName'] ?? '').toString();

      return nameA.compareTo(nameB);
    });
  }

  Future<void> loadAllFees() async {
    final snapshot = await firestore.collection('fees').get();

    fees = snapshot.docs.map((doc) {
      final data = doc.data();

      return feeFromData(doc.id, data);
    }).toList();

    sortFees();
  }

  Future<void> loadStudentFees() async {
    final snapshot = await firestore
        .collection('fees')
        .where('studentId', isEqualTo: currentUserId)
        .get();

    fees = snapshot.docs.map((doc) {
      final data = doc.data();

      return feeFromData(doc.id, data);
    }).toList();

    sortFees();
  }

  Future<void> loadParentFees() async {
    final childrenSnapshot = await firestore
        .collection('users')
        .where('role', isEqualTo: 'Student')
        .where('parentId', isEqualTo: currentUserId)
        .where('isActive', isEqualTo: true)
        .get();

    final childIds = childrenSnapshot.docs.map((doc) => doc.id).toList();

    if (childIds.isEmpty) {
      fees = [];
      return;
    }

    final loadedFees = <Map<String, dynamic>>[];

    for (final childId in childIds) {
      final feeSnapshot = await firestore
          .collection('fees')
          .where('studentId', isEqualTo: childId)
          .get();

      for (final doc in feeSnapshot.docs) {
        loadedFees.add(feeFromData(doc.id, doc.data()));
      }
    }

    fees = loadedFees;
    sortFees();
  }

  Future<void> loadAllPaymentConfirmations() async {
    final snapshot = await firestore.collection('payment_confirmations').get();

    paymentConfirmations = snapshot.docs.map((doc) {
      return paymentConfirmationFromData(doc.id, doc.data());
    }).toList();

    sortPaymentConfirmations();
  }

  Future<void> loadParentPaymentConfirmations() async {
    final snapshot = await firestore
        .collection('payment_confirmations')
        .where('parentId', isEqualTo: currentUserId)
        .get();

    paymentConfirmations = snapshot.docs.map((doc) {
      return paymentConfirmationFromData(doc.id, doc.data());
    }).toList();

    sortPaymentConfirmations();
  }

  Map<String, dynamic> feeFromData(String id, Map<String, dynamic> data) {
    return {
      'id': id,
      'title': data['title'] ?? '',
      'amount': data['amount'] ?? 0,
      'studentId': data['studentId'] ?? '',
      'studentName': data['studentName'] ?? '',
      'classId': data['classId'] ?? '',
      'className': data['className'] ?? '',
      'status': data['status'] ?? 'Unpaid',
      'note': data['note'] ?? '',
      'createdBy': data['createdBy'] ?? '',
      'createdByName': data['createdByName'] ?? '',
      'createdAt': data['createdAt'],
      'updatedAt': data['updatedAt'],
    };
  }

  Map<String, dynamic> paymentConfirmationFromData(
    String id,
    Map<String, dynamic> data,
  ) {
    return {
      'id': id,
      'feeId': data['feeId'] ?? '',
      'feeTitle': data['feeTitle'] ?? '',
      'studentId': data['studentId'] ?? '',
      'studentName': data['studentName'] ?? '',
      'parentId': data['parentId'] ?? '',
      'parentName': data['parentName'] ?? '',
      'amountPaid': data['amountPaid'] ?? 0,
      'paymentMethod': data['paymentMethod'] ?? '',
      'transactionReference': data['transactionReference'] ?? '',
      'paymentDate': data['paymentDate'],
      'message': data['message'] ?? '',
      'status': data['status'] ?? 'Pending',
      'approvedAs': data['approvedAs'] ?? '',
      'approvedBy': data['approvedBy'] ?? '',
      'approvedByName': data['approvedByName'] ?? '',
      'updatedBy': data['updatedBy'] ?? '',
      'updatedByName': data['updatedByName'] ?? '',
      'createdAt': data['createdAt'],
      'updatedAt': data['updatedAt'],
    };
  }

  void sortFees() {
    fees.sort((a, b) {
      final aCreated = a['createdAt'];
      final bCreated = b['createdAt'];

      if (aCreated is Timestamp && bCreated is Timestamp) {
        return bCreated.compareTo(aCreated);
      }

      return 0;
    });
  }

  void sortPaymentConfirmations() {
    paymentConfirmations.sort((a, b) {
      final aCreated = a['createdAt'];
      final bCreated = b['createdAt'];

      if (aCreated is Timestamp && bCreated is Timestamp) {
        return bCreated.compareTo(aCreated);
      }

      return 0;
    });
  }

  Future<void> saveFee() async {
    final title = titleController.text.trim();
    final amountText = amountController.text.trim();
    final note = noteController.text.trim();

    if (title.isEmpty) {
      showSnackBar('Please enter fee title');
      return;
    }

    if (amountText.isEmpty) {
      showSnackBar('Please enter fee amount');
      return;
    }

    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      showSnackBar('Please enter a valid amount');
      return;
    }

    if (selectedStudentId.isEmpty) {
      showSnackBar('Please select a student');
      return;
    }

    try {
      setState(() {
        isSaving = true;
      });

      await firestore.collection('fees').add({
        'title': title,
        'amount': amount,
        'studentId': selectedStudentId,
        'studentName': selectedStudentName,
        'classId': selectedClassId,
        'className': selectedClassName,
        'status': selectedStatus,
        'note': note,
        'createdBy': currentUserId,
        'createdByName': currentUserName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.pop(context);

      titleController.clear();
      amountController.clear();
      noteController.clear();

      selectedStudentId = '';
      selectedStudentName = '';
      selectedClassId = '';
      selectedClassName = '';
      selectedStatus = 'Unpaid';

      await loadInitialData();

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      showSnackBar('Fee record created successfully');
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> updateFeeStatus({
    required String feeId,
    required String status,
  }) async {
    if (feeId.isEmpty) {
      showSnackBar('Invalid fee record');
      return;
    }

    try {
      await firestore.collection('fees').doc(feeId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await loadInitialData();

      if (!mounted) return;

      showSnackBar('Fee status updated successfully');
    } catch (error) {
      if (!mounted) return;

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> deleteFee(String feeId) async {
    try {
      await firestore.collection('fees').doc(feeId).delete();

      await loadInitialData();

      if (!mounted) return;

      showSnackBar('Fee record deleted successfully');
    } catch (error) {
      if (!mounted) return;

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> confirmDeleteFee({
    required String feeId,
    required String title,
  }) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Delete Fee'),
          content: Text('Are you sure you want to delete "$title"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: AppColors.danger),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await deleteFee(feeId);
    }
  }

  Future<void> savePaymentConfirmation(Map<String, dynamic> fee) async {
    final amountText = paymentAmountController.text.trim();
    final method = paymentMethodController.text.trim();
    final reference = transactionReferenceController.text.trim();
    final message = paymentMessageController.text.trim();

    if (amountText.isEmpty) {
      showSnackBar('Please enter amount paid');
      return;
    }

    final amountPaid = double.tryParse(amountText);

    if (amountPaid == null || amountPaid <= 0) {
      showSnackBar('Please enter a valid amount paid');
      return;
    }

    if (method.isEmpty) {
      showSnackBar('Please enter payment method');
      return;
    }

    if (reference.isEmpty) {
      showSnackBar('Please enter transaction/reference number');
      return;
    }

    try {
      setState(() {
        isSaving = true;
      });

      final paymentRef = await firestore.collection('payment_confirmations').add({
        'feeId': fee['id'] ?? '',
        'feeTitle': fee['title'] ?? '',
        'studentId': fee['studentId'] ?? '',
        'studentName': fee['studentName'] ?? '',
        'parentId': currentUserId,
        'parentName': currentUserName,
        'amountPaid': amountPaid,
        'paymentMethod': method,
        'transactionReference': reference,
        'paymentDate': Timestamp.fromDate(selectedPaymentDate),
        'message': message,
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await NotificationService.notifyPaymentConfirmationToAdmins(
        paymentId: paymentRef.id,
        parentId: currentUserId,
        parentName: currentUserName,
        studentName: fee['studentName'] ?? '',
      );

      if (!mounted) return;

      Navigator.pop(context);

      paymentAmountController.clear();
      paymentMethodController.clear();
      transactionReferenceController.clear();
      paymentMessageController.clear();
      selectedPaymentDate = DateTime.now();

      await loadInitialData();

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      showSnackBar('Payment confirmation sent to admin');
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> approvePaymentConfirmation({
    required Map<String, dynamic> confirmation,
    required String newFeeStatus,
  }) async {
    final confirmationId = confirmation['id'] ?? '';
    final feeId = confirmation['feeId'] ?? '';
    final parentId = confirmation['parentId'] ?? '';

    if (confirmationId.toString().isEmpty) {
      showSnackBar('Invalid payment confirmation');
      return;
    }

    if (feeId.toString().isEmpty) {
      showSnackBar('Invalid fee linked to this confirmation');
      return;
    }

    try {
      setState(() {
        isSaving = true;
      });

      final batch = firestore.batch();

      final confirmationRef =
          firestore.collection('payment_confirmations').doc(confirmationId);

      final feeRef = firestore.collection('fees').doc(feeId);

      batch.update(confirmationRef, {
        'status': 'Approved',
        'approvedAs': newFeeStatus,
        'approvedBy': currentUserId,
        'approvedByName': currentUserName,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      batch.update(feeRef, {
        'status': newFeeStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      await NotificationService.notifyPaymentDecisionToParent(
        parentId: parentId,
        paymentId: confirmationId,
        status: 'Approved',
        adminId: currentUserId,
        adminName: currentUserName,
      );

      await loadInitialData();

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      showSnackBar('Payment approved successfully');
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> rejectPaymentConfirmation(String confirmationId) async {
    if (confirmationId.isEmpty) {
      showSnackBar('Invalid payment confirmation');
      return;
    }

    try {
      setState(() {
        isSaving = true;
      });

      final confirmationDoc = await firestore
          .collection('payment_confirmations')
          .doc(confirmationId)
          .get();

      final confirmationData = confirmationDoc.data();
      final parentId = confirmationData?['parentId'] ?? '';

      await firestore
          .collection('payment_confirmations')
          .doc(confirmationId)
          .update({
        'status': 'Rejected',
        'updatedBy': currentUserId,
        'updatedByName': currentUserName,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await NotificationService.notifyPaymentDecisionToParent(
        parentId: parentId,
        paymentId: confirmationId,
        status: 'Rejected',
        adminId: currentUserId,
        adminName: currentUserName,
      );

      await loadInitialData();

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      showSnackBar('Payment confirmation rejected');
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  void showBankDetailsSheet() {
    bankNameController.text = bankDetails?['bankName'] ?? '';
    accountNameController.text = bankDetails?['accountName'] ?? '';
    accountNumberController.text = bankDetails?['accountNumber'] ?? '';
    ibanController.text = bankDetails?['iban'] ?? '';
    ribController.text = bankDetails?['rib'] ?? '';
    bankNoteController.text = bankDetails?['note'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'School Bank Details',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: bankNameController,
                  decoration: const InputDecoration(
                    labelText: 'Bank Name',
                    prefixIcon: Icon(Icons.account_balance_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: accountNameController,
                  decoration: const InputDecoration(
                    labelText: 'Account Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: accountNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Account Number',
                    prefixIcon: Icon(Icons.numbers_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: ibanController,
                  decoration: const InputDecoration(
                    labelText: 'IBAN',
                    prefixIcon: Icon(Icons.confirmation_number_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: ribController,
                  decoration: const InputDecoration(
                    labelText: 'RIB',
                    prefixIcon: Icon(Icons.receipt_long_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: bankNoteController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Payment Note',
                    hintText: 'Example: Send proof of payment to Admin.',
                    prefixIcon: Icon(Icons.note_alt_outlined),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: isSaving ? null : saveBankDetails,
                    icon: isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      isSaving ? 'Saving...' : 'Save Bank Details',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showAddFeeSheet() {
    titleController.clear();
    amountController.clear();
    noteController.clear();

    selectedStudentId = '';
    selectedStudentName = '';
    selectedClassId = '';
    selectedClassName = '';
    selectedStatus = 'Unpaid';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create Fee Record',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Fee Title',
                        hintText: 'Example: First Semester Tuition',
                        prefixIcon: Icon(Icons.title_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        hintText: 'Example: 500',
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue:
                          selectedStudentId.isEmpty ? null : selectedStudentId,
                      decoration: const InputDecoration(
                        labelText: 'Select Student',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: students.map((student) {
                        return DropdownMenuItem<String>(
                          value: student['id'],
                          child: Text(student['fullName'] ?? 'Unknown Student'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        final selectedStudent = students.firstWhere(
                          (student) => student['id'] == value,
                          orElse: () => {},
                        );

                        setModalState(() {
                          selectedStudentId = value;
                          selectedStudentName =
                              selectedStudent['fullName'] ?? '';
                          selectedClassId = selectedStudent['classId'] ?? '';
                          selectedClassName =
                              selectedStudent['className'] ?? '';
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Payment Status',
                        prefixIcon: Icon(Icons.verified_outlined),
                      ),
                      items: statuses.map((status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        setModalState(() {
                          selectedStatus = value;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: noteController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Note',
                        hintText: 'Optional note',
                        prefixIcon: Icon(Icons.note_alt_outlined),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: isSaving ? null : saveFee,
                        icon: isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          isSaving ? 'Saving...' : 'Save Fee',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void showUpdateStatusSheet(Map<String, dynamic> fee) {
    String modalStatus = fee['status'] ?? 'Unpaid';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 34),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Update Fee Status',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    initialValue: modalStatus,
                    decoration: const InputDecoration(
                      labelText: 'Payment Status',
                      prefixIcon: Icon(Icons.verified_outlined),
                    ),
                    items: statuses.map((status) {
                      return DropdownMenuItem<String>(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;

                      setModalState(() {
                        modalStatus = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(sheetContext);

                        await updateFeeStatus(
                          feeId: fee['id'] ?? '',
                          status: modalStatus,
                        );
                      },
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Update Status'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void showPaymentConfirmationSheet(Map<String, dynamic> fee) {
    paymentAmountController.text = formatAmount(fee['amount']);
    paymentMethodController.clear();
    transactionReferenceController.clear();
    paymentMessageController.clear();
    selectedPaymentDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Confirm Payment',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      fee['title'] ?? 'School Fee',
                      style: const TextStyle(
                        color: AppColors.textGrey,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: paymentAmountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Amount Paid',
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: paymentMethodController,
                      decoration: const InputDecoration(
                        labelText: 'Payment Method',
                        hintText: 'Example: Bank transfer / Cash deposit',
                        prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: transactionReferenceController,
                      decoration: const InputDecoration(
                        labelText: 'Transaction / Reference Number',
                        hintText: 'Example: TRX123456',
                        prefixIcon: Icon(Icons.confirmation_number_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: sheetContext,
                          initialDate: selectedPaymentDate,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 365),
                          ),
                          lastDate: DateTime.now(),
                        );

                        if (pickedDate == null) return;

                        setModalState(() {
                          selectedPaymentDate = pickedDate;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_outlined,
                              color: AppColors.primaryBlue,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Payment Date: ${selectedPaymentDate.day}/${selectedPaymentDate.month}/${selectedPaymentDate.year}',
                                style: const TextStyle(
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: paymentMessageController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Message to Admin',
                        hintText:
                            'Example: I deposited the school fees today. Please confirm.',
                        prefixIcon: Icon(Icons.message_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Receipt upload will be added later when Firebase Storage is available. For now, send the transaction reference.',
                      style: TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: isSaving
                            ? null
                            : () {
                                savePaymentConfirmation(fee);
                              },
                        icon: isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              )
                            : const Icon(Icons.send_outlined),
                        label: Text(
                          isSaving ? 'Sending...' : 'Send Confirmation',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void showPaymentConfirmationsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 34),
          child: Column(
            children: [
              const Text(
                'Payment Confirmations',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: paymentConfirmations.isEmpty
                    ? const Center(
                        child: Text(
                          'No payment confirmations yet.',
                          style: TextStyle(color: AppColors.textGrey),
                        ),
                      )
                    : ListView.separated(
                        itemCount: paymentConfirmations.length,
                        separatorBuilder: (context, index) {
                          return const SizedBox(height: 12);
                        },
                        itemBuilder: (context, index) {
                          return paymentConfirmationCard(
                            paymentConfirmations[index],
                            closeSheet: () {
                              Navigator.pop(sheetContext);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget bankDetailsCard() {
    final details = bankDetails;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primaryBlue.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_balance_outlined,
                color: AppColors.primaryBlue,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'School Bank Details',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (details == null)
            Text(
              currentRole == 'Admin'
                  ? 'No bank details added yet. Tap “Bank Details” to add the school payment account.'
                  : 'School bank details are not available yet.',
              style: const TextStyle(
                color: AppColors.textGrey,
                height: 1.4,
              ),
            )
          else ...[
            Text(
              'Bank: ${details['bankName']}',
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Account Name: ${details['accountName']}',
              style: const TextStyle(color: AppColors.textGrey),
            ),
            if (details['accountNumber'].toString().isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                'Account Number: ${details['accountNumber']}',
                style: const TextStyle(color: AppColors.textGrey),
              ),
            ],
            if (details['iban'].toString().isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                'IBAN: ${details['iban']}',
                style: const TextStyle(color: AppColors.textGrey),
              ),
            ],
            if (details['rib'].toString().isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                'RIB: ${details['rib']}',
                style: const TextStyle(color: AppColors.textGrey),
              ),
            ],
            if (details['note'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Note: ${details['note']}',
                style: const TextStyle(
                  color: AppColors.textGrey,
                  height: 1.4,
                ),
              ),
            ],
          ],
          if (currentRole == 'Admin') ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 42,
              child: OutlinedButton.icon(
                onPressed: showBankDetailsSheet,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Bank Details'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String formatAmount(dynamic amount) {
    if (amount is int) {
      return amount.toStringAsFixed(0);
    }

    if (amount is double) {
      return amount.toStringAsFixed(2);
    }

    final parsed = double.tryParse(amount.toString()) ?? 0;
    return parsed.toStringAsFixed(2);
  }

  String formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }

    return 'Recently';
  }

  Color statusColor(String status) {
    if (status == 'Paid') return AppColors.softGreen;
    if (status == 'Partially Paid') return Colors.orange;
    if (status == 'Approved') return AppColors.softGreen;
    if (status == 'Rejected') return AppColors.danger;
    if (status == 'Pending') return Colors.orange;
    return AppColors.danger;
  }

  Widget feeCard(Map<String, dynamic> fee) {
    final feeId = fee['id'] ?? '';
    final title = fee['title'] ?? 'Untitled Fee';
    final amount = fee['amount'] ?? 0;
    final studentName = fee['studentName'] ?? '';
    final className = fee['className'] ?? '';
    final status = fee['status'] ?? 'Unpaid';
    final note = fee['note'] ?? '';
    final createdAt = fee['createdAt'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.payments_outlined,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Amount: ${formatAmount(amount)}',
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                if (studentName.toString().isNotEmpty)
                  Text(
                    'Student: $studentName',
                    style: const TextStyle(color: AppColors.textGrey),
                  ),
                if (className.toString().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    'Class: $className',
                    style: const TextStyle(color: AppColors.textGrey),
                  ),
                ],
                if (note.toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Note: $note',
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Created: ${formatDate(createdAt)}',
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor(status).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor(status),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (canCreateFee)
                      TextButton(
                        onPressed: () {
                          showUpdateStatusSheet(fee);
                        },
                        child: const Text('Update'),
                      ),
                    if (isParent && status != 'Paid')
                      TextButton.icon(
                        onPressed: () {
                          showPaymentConfirmationSheet(fee);
                        },
                        icon: const Icon(Icons.send_outlined),
                        label: const Text('I Have Paid'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (canCreateFee)
            IconButton(
              onPressed: () {
                confirmDeleteFee(
                  feeId: feeId,
                  title: title,
                );
              },
              icon: const Icon(
                Icons.delete_outline,
                color: AppColors.danger,
              ),
            ),
        ],
      ),
    );
  }

  Widget paymentConfirmationCard(
    Map<String, dynamic> confirmation, {
    required VoidCallback closeSheet,
  }) {
    final status = confirmation['status'] ?? 'Pending';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            confirmation['feeTitle'] ?? 'Payment Confirmation',
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Student: ${confirmation['studentName']}',
            style: const TextStyle(color: AppColors.textGrey),
          ),
          const SizedBox(height: 5),
          Text(
            'Parent: ${confirmation['parentName']}',
            style: const TextStyle(color: AppColors.textGrey),
          ),
          const SizedBox(height: 5),
          Text(
            'Amount Paid: ${formatAmount(confirmation['amountPaid'])}',
            style: const TextStyle(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Method: ${confirmation['paymentMethod']}',
            style: const TextStyle(color: AppColors.textGrey),
          ),
          const SizedBox(height: 5),
          Text(
            'Reference: ${confirmation['transactionReference']}',
            style: const TextStyle(color: AppColors.textGrey),
          ),
          const SizedBox(height: 5),
          Text(
            'Payment Date: ${formatDate(confirmation['paymentDate'])}',
            style: const TextStyle(color: AppColors.textGrey),
          ),
          if (confirmation['message'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Message: ${confirmation['message']}',
              style: const TextStyle(
                color: AppColors.textGrey,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: statusColor(status).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor(status),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          if (currentRole == 'Admin' && status == 'Pending') ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: isSaving
                      ? null
                      : () {
                          closeSheet();

                          Future.delayed(
                            const Duration(milliseconds: 250),
                            () {
                              if (!mounted) return;

                              approvePaymentConfirmation(
                                confirmation: confirmation,
                                newFeeStatus: 'Paid',
                              );
                            },
                          );
                        },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Approve Paid'),
                ),
                OutlinedButton.icon(
                  onPressed: isSaving
                      ? null
                      : () {
                          closeSheet();

                          Future.delayed(
                            const Duration(milliseconds: 250),
                            () {
                              if (!mounted) return;

                              approvePaymentConfirmation(
                                confirmation: confirmation,
                                newFeeStatus: 'Partially Paid',
                              );
                            },
                          );
                        },
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Partial'),
                ),
                TextButton.icon(
                  onPressed: isSaving
                      ? null
                      : () {
                          closeSheet();

                          Future.delayed(
                            const Duration(milliseconds: 250),
                            () {
                              if (!mounted) return;

                              rejectPaymentConfirmation(
                                confirmation['id'] ?? '',
                              );
                            },
                          );
                        },
                  icon: const Icon(
                    Icons.close_outlined,
                    color: AppColors.danger,
                  ),
                  label: const Text(
                    'Reject',
                    style: TextStyle(color: AppColors.danger),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget paymentConfirmationsPreview() {
    if (currentRole != 'Admin') {
      return const SizedBox();
    }

    final pendingCount = paymentConfirmations
        .where((item) => item['status'] == 'Pending')
        .length;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            color: Colors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$pendingCount pending payment confirmation(s)',
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: showPaymentConfirmationsSheet,
            child: const Text('View'),
          ),
        ],
      ),
    );
  }

  Widget parentPaymentConfirmationsPreview() {
    if (currentRole != 'Parent' || paymentConfirmations.isEmpty) {
      return const SizedBox();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.softGreen.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.softGreen.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            color: AppColors.softGreen,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${paymentConfirmations.length} payment confirmation(s) sent',
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: showPaymentConfirmationsSheet,
            child: const Text('View'),
          ),
        ],
      ),
    );
  }

  Widget emptyState() {
    String message = 'No fee records found yet.';

    if (currentRole == 'Admin') {
      message = 'No fee records found yet. Tap Add Fee to create one.';
    }

    if (currentRole == 'Parent') {
      message =
          'No fee records found for your child yet. Make sure your child is assigned to your parent account.';
    }

    if (currentRole == 'Student') {
      message = 'No fee records found for your account yet.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textGrey,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  void showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Fees';

    if (currentRole == 'Admin') title = 'Fees Management';
    if (currentRole == 'Parent') title = 'Child Fees';
    if (currentRole == 'Student') title = 'My Fees';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (currentRole == 'Admin')
            IconButton(
              onPressed: showBankDetailsSheet,
              icon: const Icon(Icons.account_balance_outlined),
            ),
          IconButton(
            onPressed: isLoading ? null : loadInitialData,
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      floatingActionButton: canCreateFee
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: AppColors.white,
              onPressed: showAddFeeSheet,
              icon: const Icon(Icons.add),
              label: const Text('Add Fee'),
            )
          : null,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      bankDetailsCard(),
                      paymentConfirmationsPreview(),
                      parentPaymentConfirmationsPreview(),
                      Expanded(
                        child: fees.isEmpty
                            ? emptyState()
                            : ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(18, 18, 18, 90),
                                itemCount: fees.length,
                                separatorBuilder: (context, index) {
                                  return const SizedBox(height: 12);
                                },
                                itemBuilder: (context, index) {
                                  return feeCard(fees[index]);
                                },
                              ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
