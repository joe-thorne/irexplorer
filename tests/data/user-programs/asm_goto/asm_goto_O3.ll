; ModuleID = '/workspace/user-programs/asm_goto.c'
source_filename = "/workspace/user-programs/asm_goto.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; Function Attrs: nounwind uwtable
define dso_local range(i32 0, 2) i32 @is_positive(i32 noundef %x) local_unnamed_addr #0 !dbg !14 {
entry:
    #dbg_value(i32 %x, !20, !DIExpression(), !22)
  callbr void asm sideeffect "testl $0, $0\0A\09jg ${1:l}", "r,!i,~{cc},~{dirflag},~{fpsr},~{flags}"(i32 %x) #1
          to label %return [label %positive], !dbg !23, !srcloc !24

positive:                                         ; preds = %entry
    #dbg_label(!21, !25)
  br label %return, !dbg !26

return:                                           ; preds = %entry, %positive
  %retval.0 = phi i32 [ 1, %positive ], [ 0, %entry ], !dbg !22
  ret i32 %retval.0, !dbg !27
}

; Function Attrs: nounwind uwtable
define dso_local range(i32 0, 2) i32 @main() local_unnamed_addr #0 !dbg !28 {
entry:
    #dbg_value(i32 5, !20, !DIExpression(), !31)
  callbr void asm sideeffect "testl $0, $0\0A\09jg ${1:l}", "r,!i,~{cc},~{dirflag},~{fpsr},~{flags}"(i32 5) #1
          to label %land.end [label %land.rhs], !dbg !33, !srcloc !24

land.rhs:                                         ; preds = %entry
    #dbg_label(!21, !34)
    #dbg_value(i32 -5, !20, !DIExpression(), !35)
  callbr void asm sideeffect "testl $0, $0\0A\09jg ${1:l}", "r,!i,~{cc},~{dirflag},~{fpsr},~{flags}"(i32 -5) #1
          to label %land.end [label %positive.i3], !dbg !37, !srcloc !24

positive.i3:                                      ; preds = %land.rhs
    #dbg_label(!21, !38)
  br label %land.end, !dbg !39

land.end:                                         ; preds = %entry, %positive.i3, %land.rhs
  %not. = phi i32 [ 0, %land.rhs ], [ 1, %positive.i3 ], [ 1, %entry ], !dbg !40
  ret i32 %not., !dbg !41
}

attributes #0 = { nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind }

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!2, !3, !4, !5, !6, !7, !8}
!llvm.ident = !{!9}
!llvm.errno.tbaa = !{!10}

!0 = distinct !DICompileUnit(language: DW_LANG_C11, file: !1, producer: "clang version 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, splitDebugInlining: false, nameTableKind: None)
!1 = !DIFile(filename: "/workspace/user-programs/asm_goto.c", directory: "/workspace", checksumkind: CSK_MD5, checksum: "9b7683a669d768aeafd26d8337345695")
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
!14 = distinct !DISubprogram(name: "is_positive", scope: !15, file: !15, line: 1, type: !16, scopeLine: 1, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !19, keyInstructions: true)
!15 = !DIFile(filename: "user-programs/asm_goto.c", directory: "/workspace", checksumkind: CSK_MD5, checksum: "9b7683a669d768aeafd26d8337345695")
!16 = !DISubroutineType(types: !17)
!17 = !{!18, !18}
!18 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!19 = !{!20, !21}
!20 = !DILocalVariable(name: "x", arg: 1, scope: !14, file: !15, line: 1, type: !18)
!21 = !DILabel(scope: !14, name: "positive", file: !15, line: 4, column: 1)
!22 = !DILocation(line: 0, scope: !14)
!23 = !DILocation(line: 2, column: 5, scope: !14, atomGroup: 1, atomRank: 1)
!24 = !{i64 40, i64 55}
!25 = !DILocation(line: 4, column: 1, scope: !14)
!26 = !DILocation(line: 5, column: 5, scope: !14, atomGroup: 3, atomRank: 1)
!27 = !DILocation(line: 6, column: 1, scope: !14, atomGroup: 4, atomRank: 1)
!28 = distinct !DISubprogram(name: "main", scope: !15, file: !15, line: 8, type: !29, scopeLine: 8, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, keyInstructions: true)
!29 = !DISubroutineType(types: !30)
!30 = !{!18}
!31 = !DILocation(line: 0, scope: !14, inlinedAt: !32)
!32 = distinct !DILocation(line: 9, column: 12, scope: !28)
!33 = !DILocation(line: 2, column: 5, scope: !14, inlinedAt: !32, atomGroup: 1, atomRank: 1)
!34 = !DILocation(line: 4, column: 1, scope: !14, inlinedAt: !32)
!35 = !DILocation(line: 0, scope: !14, inlinedAt: !36)
!36 = distinct !DILocation(line: 9, column: 31, scope: !28)
!37 = !DILocation(line: 2, column: 5, scope: !14, inlinedAt: !36, atomGroup: 1, atomRank: 1)
!38 = !DILocation(line: 4, column: 1, scope: !14, inlinedAt: !36)
!39 = !DILocation(line: 5, column: 5, scope: !14, inlinedAt: !36, atomGroup: 3, atomRank: 1)
!40 = !DILocation(line: 0, scope: !28)
!41 = !DILocation(line: 9, column: 5, scope: !28, atomGroup: 1, atomRank: 1)
