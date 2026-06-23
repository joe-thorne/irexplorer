; ModuleID = '/workspace/artefacts/curated/score/score_02_instcombine.ll'
source_filename = "/workspace/examples/curated/score.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @score(i32 noundef %x, i32 noundef %scale) #0 !dbg !10 {
entry:
    #dbg_value(i32 %x, !16, !DIExpression(), !17)
    #dbg_value(i32 %scale, !18, !DIExpression(), !17)
  %mul = shl nsw i32 %scale, 5, !dbg !19
    #dbg_value(i32 %mul, !20, !DIExpression(), !17)
    #dbg_value(!DIArgList(i32 %scale, i32 %scale, i32 %scale, i32 %scale), !21, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 3, DW_OP_mul, DW_OP_LLVM_arg, 1, DW_OP_LLVM_arg, 2, DW_OP_mul, DW_OP_minus, DW_OP_stack_value), !17)
  %sub3 = add nsw i32 %x, -128, !dbg !22
    #dbg_value(i32 %sub3, !23, !DIExpression(), !17)
  %mul4 = mul nsw i32 %sub3, %scale, !dbg !24
    #dbg_value(i32 %mul4, !25, !DIExpression(), !17)
  %cmp = icmp sgt i32 %mul4, %mul, !dbg !26
  %mul.mul4 = select i1 %cmp, i32 %mul, i32 %mul4, !dbg !17
  ret i32 %mul.mul4, !dbg !28
}

attributes #0 = { noinline nounwind uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!2, !3, !4, !5, !6, !7, !8}
!llvm.ident = !{!9}

!0 = distinct !DICompileUnit(language: DW_LANG_C11, file: !1, producer: "clang version 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, splitDebugInlining: false, nameTableKind: None)
!1 = !DIFile(filename: "/workspace/examples/curated/score.c", directory: "/workspace", checksumkind: CSK_MD5, checksum: "5160dd22049a214b2c2adf12988e5154")
!2 = !{i32 7, !"Dwarf Version", i32 5}
!3 = !{i32 2, !"Debug Info Version", i32 3}
!4 = !{i32 1, !"wchar_size", i32 4}
!5 = !{i32 8, !"PIC Level", i32 2}
!6 = !{i32 7, !"PIE Level", i32 2}
!7 = !{i32 7, !"uwtable", i32 2}
!8 = !{i32 7, !"frame-pointer", i32 2}
!9 = !{!"clang version 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)"}
!10 = distinct !DISubprogram(name: "score", scope: !11, file: !11, line: 1, type: !12, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !15)
!11 = !DIFile(filename: "examples/curated/score.c", directory: "/workspace", checksumkind: CSK_MD5, checksum: "5160dd22049a214b2c2adf12988e5154")
!12 = !DISubroutineType(types: !13)
!13 = !{!14, !14, !14}
!14 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!15 = !{}
!16 = !DILocalVariable(name: "x", arg: 1, scope: !10, file: !11, line: 1, type: !14)
!17 = !DILocation(line: 0, scope: !10)
!18 = !DILocalVariable(name: "scale", arg: 2, scope: !10, file: !11, line: 1, type: !14)
!19 = !DILocation(line: 2, column: 26, scope: !10)
!20 = !DILocalVariable(name: "limit", scope: !10, file: !11, line: 2, type: !14)
!21 = !DILocalVariable(name: "wasted", scope: !10, file: !11, line: 3, type: !14)
!22 = !DILocation(line: 4, column: 22, scope: !10)
!23 = !DILocalVariable(name: "adjusted", scope: !10, file: !11, line: 4, type: !14)
!24 = !DILocation(line: 5, column: 29, scope: !10)
!25 = !DILocalVariable(name: "weighted", scope: !10, file: !11, line: 5, type: !14)
!26 = !DILocation(line: 7, column: 18, scope: !27)
!27 = distinct !DILexicalBlock(scope: !10, file: !11, line: 7, column: 9)
!28 = !DILocation(line: 11, column: 1, scope: !10)
