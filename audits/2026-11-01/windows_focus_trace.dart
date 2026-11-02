// Diagnostic entry point: logs the real framework tree after input focus moves.
// Run from apps/windows with flutter run -d windows -t
// ../../audits/2026-11-01/windows_focus_trace.dart -a --settings
import 'dart:ui' show Tristate;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../apps/windows/lib/main.dart' as production;

void main(List<String> args) {
  WidgetsFlutterBinding.ensureInitialized();
  FocusManager.instance.addListener(() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint(
        'FOCUS_TRACE ${FocusManager.instance.primaryFocus?.debugLabel}',
      );
      bool scan(SemanticsNode node) {
        final data = node.getSemanticsData();
        if (data.flagsCollection.isFocused == Tristate.isTrue) {
          debugPrint(
            'FOCUSED_DATA id=${node.id} merged=${node.isMergedIntoParent} label=${data.label}',
          );
        }
        node.visitChildren(scan);
        return true;
      }

      void scanOwner(PipelineOwner owner) {
        final root = owner.semanticsOwner?.rootSemanticsNode;
        if (root != null) scan(root);
        owner.visitChildren(scanOwner);
      }

      scanOwner(RendererBinding.instance.rootPipelineOwner);
      debugDumpSemanticsTree(DebugSemanticsDumpOrder.traversalOrder);
    });
  });
  production.main(args);
}
