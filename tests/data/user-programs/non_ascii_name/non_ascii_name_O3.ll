; ModuleID = '/workspace/user-programs/non_ascii_name.c'
source_filename = "/workspace/user-programs/non_ascii_name.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local i32 @"caf\C3\A9_total"(i32 noundef %cups, i32 noundef %price) local_unnamed_addr #0 !dbg !14 {
entry:
    #dbg_value(i32 %cups, !20, !DIExpression(), !22)
    #dbg_value(i32 %price, !21, !DIExpression(), !22)
  %mul = mul nsw i32 %price, %cups, !dbg !23
  ret i32 %mul, !dbg !24
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local noundef range(i32 0, 2) i32 @main() local_unnamed_addr #0 !dbg !25 {
entry:
  ret i32 0, !dbg !28
}

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!2, !3, !4, !5, !6, !7, !8}
!llvm.ident = !{!9}
!llvm.errno.tbaa = !{!10}

!0 = distinct !DICompileUnit(language: DW_LANG_C11, file: !1, producer: "clang version 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, splitDebugInlining: false, nameTableKind: None)
!1 = !DIFile(filename: "/workspace/user-programs/non_ascii_name.c", directory: "/workspace", checksumkind: CSK_MD5, checksum: "110a8b231563f0173026ce1c6538904b")
!2 = !{i32 7, !"Dwarf Version", i32 5}
!3 = !{i32 2, !"Debug Info Version", i32 3}
!4 = !{i32 1, !"wchar_size", i32 4}
!5 = !{i32 8, !"PIC Level", i32 2}
!6 = !{i32 7, !"PIE Level", i32 2}
!7 = !{i32 7, !"uwtable", i32 2}
!8 = !{i32 7, !"debug-info-assignment-tracking", i1 true}
!9 = !{!"clang version 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)"}
!10 = !{!11, !11, i64 0}
!11 = !{!"int", !12, i64 0}
!12 = !{!"omnipotent char", !13, i64 0}
!13 = !{!"Simple C/C++ TBAA"}
!14 = distinct !DISubprogram(name: "caf\C3\A9_total", scope: !15, file: !15, line: 2, type: !16, scopeLine: 2, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !19, keyInstructions: true)
!15 = !DIFile(filename: "user-programs/non_ascii_name.c", directory: "/workspace", checksumkind: CSK_MD5, checksum: "110a8b231563f0173026ce1c6538904b")
!16 = !DISubroutineType(types: !17)
!17 = !{!18, !18, !18}
!18 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!19 = !{!20, !21}
!20 = !DILocalVariable(name: "cups", arg: 1, scope: !14, file: !15, line: 2, type: !18)
!21 = !DILocalVariable(name: "price", arg: 2, scope: !14, file: !15, line: 2, type: !18)
!22 = !DILocation(line: 0, scope: !14)
!23 = !DILocation(line: 3, column: 17, scope: !14, atomGroup: 1, atomRank: 2)
!24 = !DILocation(line: 3, column: 5, scope: !14, atomGroup: 1, atomRank: 1)
!25 = distinct !DISubprogram(name: "main", scope: !15, file: !15, line: 6, type: !26, scopeLine: 6, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, keyInstructions: true)
!26 = !DISubroutineType(types: !27)
!27 = !{!18}
!28 = !DILocation(line: 7, column: 5, scope: !25, atomGroup: 1, atomRank: 1)
