; ModuleID = '/workspace/examples/curated/score.c'
source_filename = "/workspace/examples/curated/score.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local range(i32 -2147483648, 2147483617) i32 @score(i32 noundef %x, i32 noundef %scale) local_unnamed_addr #0 !dbg !14 {
entry:
    #dbg_value(i32 %x, !20, !DIExpression(), !26)
    #dbg_value(i32 %scale, !21, !DIExpression(), !26)
  %mul = shl nsw i32 %scale, 5, !dbg !27
    #dbg_value(i32 %mul, !22, !DIExpression(), !26)
    #dbg_value(i32 0, !23, !DIExpression(), !26)
  %sub3 = add nsw i32 %x, -128, !dbg !28
    #dbg_value(i32 %sub3, !24, !DIExpression(), !26)
  %mul4 = mul nsw i32 %sub3, %scale, !dbg !29
    #dbg_value(i32 %mul4, !25, !DIExpression(), !26)
  %mul.mul4 = tail call i32 @llvm.smin.i32(i32 %mul4, i32 %mul), !dbg !26
  ret i32 %mul.mul4, !dbg !30
}

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smin.i32(i32, i32) #1

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none) }

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!2, !3, !4, !5, !6, !7, !8}
!llvm.ident = !{!9}
!llvm.errno.tbaa = !{!10}

!0 = distinct !DICompileUnit(language: DW_LANG_C11, file: !1, producer: "clang version 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, splitDebugInlining: false, nameTableKind: None)
!1 = !DIFile(filename: "/workspace/examples/curated/score.c", directory: "/workspace", checksumkind: CSK_MD5, checksum: "5160dd22049a214b2c2adf12988e5154")
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
!14 = distinct !DISubprogram(name: "score", scope: !15, file: !15, line: 1, type: !16, scopeLine: 1, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !19, keyInstructions: true)
!15 = !DIFile(filename: "examples/curated/score.c", directory: "/workspace", checksumkind: CSK_MD5, checksum: "5160dd22049a214b2c2adf12988e5154")
!16 = !DISubroutineType(types: !17)
!17 = !{!18, !18, !18}
!18 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!19 = !{!20, !21, !22, !23, !24, !25}
!20 = !DILocalVariable(name: "x", arg: 1, scope: !14, file: !15, line: 1, type: !18)
!21 = !DILocalVariable(name: "scale", arg: 2, scope: !14, file: !15, line: 1, type: !18)
!22 = !DILocalVariable(name: "limit", scope: !14, file: !15, line: 2, type: !18)
!23 = !DILocalVariable(name: "wasted", scope: !14, file: !15, line: 3, type: !18)
!24 = !DILocalVariable(name: "adjusted", scope: !14, file: !15, line: 4, type: !18)
!25 = !DILocalVariable(name: "weighted", scope: !14, file: !15, line: 5, type: !18)
!26 = !DILocation(line: 0, scope: !14)
!27 = !DILocation(line: 2, column: 26, scope: !14, atomGroup: 1, atomRank: 2)
!28 = !DILocation(line: 4, column: 22, scope: !14, atomGroup: 3, atomRank: 2)
!29 = !DILocation(line: 5, column: 29, scope: !14, atomGroup: 4, atomRank: 2)
!30 = !DILocation(line: 11, column: 1, scope: !14, atomGroup: 8, atomRank: 1)
