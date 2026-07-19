import 'package:file_explorer/features/transfers/data/repositories/fake_transfer_executor.dart';
import 'package:file_explorer/features/transfers/domain/repositories/transfer_executor.dart';

TransferExecutor createTransferExecutor() {
  return const FakeTransferExecutor();
}
