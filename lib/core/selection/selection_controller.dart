import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'selection_model.dart';

class SelectionController extends Notifier<SelectionModel?> {
  @override
  SelectionModel? build() => null;

  void select(SelectionModel selection) => state = selection;

  void clear() => state = null;
}

final selectionProvider =
    NotifierProvider<SelectionController, SelectionModel?>(
      SelectionController.new,
    );
