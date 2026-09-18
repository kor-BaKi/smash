import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/taxi_settlement_api.dart';
import '../../../core/theme/app_theme.dart';

class TaxiSettlementPage extends ConsumerStatefulWidget {
  final int activityId;
  final int groupId;
  final int groupNumber;
  final int myUserId;

  const TaxiSettlementPage({
    super.key,
    required this.activityId,
    required this.groupId,
    required this.groupNumber,
    required this.myUserId,
  });

  @override
  ConsumerState<TaxiSettlementPage> createState() => _TaxiSettlementPageState();
}

class _TaxiSettlementPageState extends ConsumerState<TaxiSettlementPage> {
  Map<String, dynamic>? _settlement;
  bool _isLoading = true;
  bool _isCreating = false;
  bool _sendNotification = true;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _bankController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettlement();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _bankController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  Future<void> _loadSettlement() async {
    try {
      final data = await TaxiSettlementApi.getSettlement(
        widget.activityId,
        widget.groupId,
      );
      setState(() {
        _settlement = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createSettlement() async {
    if (_amountController.text.isEmpty ||
        _bankController.text.isEmpty ||
        _accountController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('모든 항목을 입력해주세요.')));
      return;
    }

    final amount = int.tryParse(
      _amountController.text.replaceAll(',', '').replaceAll('원', ''),
    );
    if (amount == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('금액을 올바르게 입력해주세요.')));
      return;
    }

    try {
      final data = await TaxiSettlementApi.create(
        widget.activityId,
        widget.groupId,
        amount,
        _bankController.text.trim(),
        _accountController.text.trim(),
        sendNotification: _sendNotification,
      );
      setState(() {
        _settlement = data;
        _isCreating = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('정산 생성에 실패했습니다.')));
      }
    }
  }

  Future<void> _togglePayment(int userId) async {
    try {
      await TaxiSettlementApi.togglePayment(_settlement!['id'], userId);
      await _loadSettlement();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('처리에 실패했습니다.')));
      }
    }
  }

  Future<void> _deleteSettlement() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          '정산 삭제',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          '정산을 삭제할까요?',
          style: TextStyle(color: AppColors.gray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소', style: TextStyle(color: AppColors.gray)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              '삭제',
              style: TextStyle(
                color: AppColors.coral,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await TaxiSettlementApi.delete(_settlement!['id']);
        setState(() => _settlement = null);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('정산이 삭제되었습니다.')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('삭제에 실패했습니다.')));
        }
      }
    }
  }

  Future<void> _openToss() async {
    final accountNumber = _settlement!['accountNumber'].toString().replaceAll(
      '-',
      '',
    );
    final url =
        'supertoss://send?bank=${_settlement!['accountBank']}&accountNo=$accountNumber&amount=${_settlement!['amountPerPerson']}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('토스 앱을 열 수 없습니다.')));
      }
    }
  }

  void _copyAccount() {
    Clipboard.setData(ClipboardData(text: _settlement!['accountNumber']));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('계좌번호가 복사되었습니다.')));
  }

  bool get _isPayer =>
      _settlement != null &&
      (_settlement!['payments'] as List).every(
        (p) => p['userId'] != widget.myUserId,
      );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: Text('${widget.groupNumber}호차 택시비 정산'),
          actions: [
            if (_settlement != null && _isPayer)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.coral),
                onPressed: _deleteSettlement,
              ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.lime),
              )
            : _settlement == null
            ? _buildCreateView()
            : _buildSettlementView(),
      ),
    );
  }

  Widget _buildCreateView() {
    if (!_isCreating) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.calculate_outlined,
              size: 48,
              color: AppColors.darkGray,
            ),
            const SizedBox(height: 16),
            const Text(
              '아직 정산이 없습니다.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.gray,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '결제자가 정산을 시작할 수 있습니다.',
              style: TextStyle(fontSize: 13, color: AppColors.gray),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => setState(() => _isCreating = true),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lime,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  '정산 시작',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('총 금액'),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.white),
            decoration: const InputDecoration(
              hintText: '예: 32000',
              suffixText: '원',
            ),
          ),
          const SizedBox(height: 16),
          _buildLabel('은행명'),
          const SizedBox(height: 8),
          TextField(
            controller: _bankController,
            style: const TextStyle(color: AppColors.white),
            decoration: const InputDecoration(hintText: '예: 카카오뱅크'),
          ),
          const SizedBox(height: 16),
          _buildLabel('계좌번호'),
          const SizedBox(height: 8),
          TextField(
            controller: _accountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.white),
            decoration: const InputDecoration(hintText: '예: 3333011234567'),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SwitchListTile(
              title: const Text(
                '알림 보내기',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.white,
                ),
              ),
              subtitle: const Text(
                '동승자에게 정산 요청 알림을 전송합니다.',
                style: TextStyle(fontSize: 12, color: AppColors.gray),
              ),
              value: _sendNotification,
              activeColor: AppColors.lime,
              activeTrackColor: AppColors.lime.withValues(alpha: 0.3),
              inactiveThumbColor: AppColors.darkGray,
              inactiveTrackColor: AppColors.card2,
              onChanged: (v) => setState(() => _sendNotification = v),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _createSettlement,
              child: const Text(
                '정산 시작',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementView() {
    final payments = _settlement!['payments'] as List;
    final isPayer = _isPayer;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 정산 정보 카드
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.directions_car,
                      size: 16,
                      color: AppColors.lime,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.groupNumber}호차 정산',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _InfoRow(label: '결제자', value: _settlement!['payerName']),
                _InfoRow(
                  label: '총 금액',
                  value:
                      '${_settlement!['totalAmount'].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원',
                ),
                _InfoRow(
                  label: '1인당',
                  value:
                      '${_settlement!['amountPerPerson'].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원',
                  highlight: true,
                ),
                _InfoRow(label: '은행', value: _settlement!['accountBank']),
                _InfoRow(label: '계좌번호', value: _settlement!['accountNumber']),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 송금 버튼 (동승자만)
          if (!isPayer) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openToss,
                icon: const Icon(Icons.send, size: 16),
                label: const Text('토스로 바로 송금'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _copyAccount,
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('계좌번호 복사'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.lime,
                  side: const BorderSide(color: AppColors.lime),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // 납부 현황
          const Text(
            '납부 현황',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 12),
          ...payments.map((payment) {
            final isMe = payment['userId'] == widget.myUserId;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.card2,
                    child: Text(
                      payment['userName'].substring(0, 1),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.gray,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${payment['userName']}${isMe ? ' (나)' : ''}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                        if (payment['isPaid'] && payment['paidAt'] != null)
                          Text(
                            payment['paidAt'],
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.gray,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isPayer)
                    Checkbox(
                      value: payment['isPaid'],
                      activeColor: AppColors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: (_) => _togglePayment(payment['userId']),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: payment['isPaid']
                            ? AppColors.greenTag
                            : AppColors.grayTag,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        payment['isPaid'] ? '납부완료' : '미납',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: payment['isPaid']
                              ? AppColors.greenTagText
                              : AppColors.grayTagText,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: AppColors.gray,
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _InfoRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.gray),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: highlight ? 16 : 13,
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
              color: highlight ? AppColors.lime : AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}
