; ModuleID = '/workspace/artifacts/curated/binary_search/binary_search_06_loop_canonical.ll'
source_filename = "/workspace/examples/curated/binary_search.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @binary_search(ptr noundef %a, i32 noundef %n, i32 noundef %key) #0 !dbg !12 {
entry:
    #dbg_value(ptr %a, !19, !DIExpression(), !20)
    #dbg_value(i32 %n, !21, !DIExpression(), !20)
    #dbg_value(i32 %key, !22, !DIExpression(), !20)
    #dbg_value(i32 0, !23, !DIExpression(), !20)
    #dbg_value(i32 %n, !24, !DIExpression(), !20)
  %cmp2 = icmp slt i32 0, %n, !dbg !25
  br i1 %cmp2, label %while.body.lr.ph, label %while.end, !dbg !26

while.body.lr.ph:                                 ; preds = %entry
  br label %while.body, !dbg !26

while.body:                                       ; preds = %while.body.lr.ph, %while.body
  %hi.04 = phi i32 [ %n, %while.body.lr.ph ], [ %hi.1, %while.body ]
  %lo.03 = phi i32 [ 0, %while.body.lr.ph ], [ %lo.1, %while.body ]
    #dbg_value(i32 %hi.04, !24, !DIExpression(), !20)
    #dbg_value(i32 %lo.03, !23, !DIExpression(), !20)
  %sub = sub nsw i32 %hi.04, %lo.03, !dbg !27
  %div1 = lshr i32 %sub, 1, !dbg !29
  %add = add nsw i32 %lo.03, %div1, !dbg !30
    #dbg_value(i32 %add, !31, !DIExpression(), !32)
  %idxprom = sext i32 %add to i64, !dbg !33
  %arrayidx = getelementptr inbounds i32, ptr %a, i64 %idxprom, !dbg !33
  %0 = load i32, ptr %arrayidx, align 4, !dbg !33
  %cmp1 = icmp slt i32 %0, %key, !dbg !35
  %add2 = add nsw i32 %add, 1, !dbg !35
  %lo.1 = select i1 %cmp1, i32 %add2, i32 %lo.03, !dbg !35
  %hi.1 = select i1 %cmp1, i32 %hi.04, i32 %add, !dbg !35
    #dbg_value(i32 %hi.1, !24, !DIExpression(), !20)
    #dbg_value(i32 %lo.1, !23, !DIExpression(), !20)
  %cmp = icmp slt i32 %lo.1, %hi.1, !dbg !25
  br i1 %cmp, label %while.body, label %while.cond.while.end_crit_edge, !dbg !26, !llvm.loop !36

while.cond.while.end_crit_edge:                   ; preds = %while.body
  %split = phi i32 [ %lo.1, %while.body ]
  br label %while.end, !dbg !26

while.end:                                        ; preds = %while.cond.while.end_crit_edge, %entry
  %lo.0.lcssa = phi i32 [ %split, %while.cond.while.end_crit_edge ], [ 0, %entry ], !dbg !20
  %cmp3 = icmp slt i32 %lo.0.lcssa, %n, !dbg !39
  br i1 %cmp3, label %land.lhs.true, label %if.end8, !dbg !41

land.lhs.true:                                    ; preds = %while.end
  %idxprom4 = sext i32 %lo.0.lcssa to i64, !dbg !42
  %arrayidx5 = getelementptr inbounds i32, ptr %a, i64 %idxprom4, !dbg !42
  %1 = load i32, ptr %arrayidx5, align 4, !dbg !42
  %cmp6 = icmp eq i32 %1, %key, !dbg !43
  br i1 %cmp6, label %return, label %if.end8, !dbg !41

if.end8:                                          ; preds = %land.lhs.true, %while.end
  br label %return, !dbg !44

return:                                           ; preds = %if.end8, %land.lhs.true
  %retval.0 = phi i32 [ -1, %if.end8 ], [ %lo.0.lcssa, %land.lhs.true ], !dbg !20
  ret i32 %retval.0, !dbg !45
}

attributes #0 = { noinline nounwind uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!4, !5, !6, !7, !8, !9, !10}
!llvm.ident = !{!11}

!0 = distinct !DICompileUnit(language: DW_LANG_C11, file: !1, producer: "clang version 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, retainedTypes: !2, splitDebugInlining: false, nameTableKind: None)
!1 = !DIFile(filename: "/workspace/examples/curated/binary_search.c", directory: "/workspace", checksumkind: CSK_MD5, checksum: "0b3f215bd3150ba37f1d3f81c36b6227")
!2 = !{!3}
!3 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!4 = !{i32 7, !"Dwarf Version", i32 5}
!5 = !{i32 2, !"Debug Info Version", i32 3}
!6 = !{i32 1, !"wchar_size", i32 4}
!7 = !{i32 8, !"PIC Level", i32 2}
!8 = !{i32 7, !"PIE Level", i32 2}
!9 = !{i32 7, !"uwtable", i32 2}
!10 = !{i32 7, !"frame-pointer", i32 2}
!11 = !{!"clang version 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)"}
!12 = distinct !DISubprogram(name: "binary_search", scope: !13, file: !13, line: 1, type: !14, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !18)
!13 = !DIFile(filename: "examples/curated/binary_search.c", directory: "/workspace", checksumkind: CSK_MD5, checksum: "0b3f215bd3150ba37f1d3f81c36b6227")
!14 = !DISubroutineType(types: !15)
!15 = !{!3, !16, !3, !3}
!16 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !17, size: 64)
!17 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !3)
!18 = !{}
!19 = !DILocalVariable(name: "a", arg: 1, scope: !12, file: !13, line: 1, type: !16)
!20 = !DILocation(line: 0, scope: !12)
!21 = !DILocalVariable(name: "n", arg: 2, scope: !12, file: !13, line: 1, type: !3)
!22 = !DILocalVariable(name: "key", arg: 3, scope: !12, file: !13, line: 1, type: !3)
!23 = !DILocalVariable(name: "lo", scope: !12, file: !13, line: 2, type: !3)
!24 = !DILocalVariable(name: "hi", scope: !12, file: !13, line: 3, type: !3)
!25 = !DILocation(line: 5, column: 15, scope: !12)
!26 = !DILocation(line: 5, column: 5, scope: !12)
!27 = !DILocation(line: 6, column: 28, scope: !28)
!28 = distinct !DILexicalBlock(scope: !12, file: !13, line: 5, column: 21)
!29 = !DILocation(line: 6, column: 34, scope: !28)
!30 = !DILocation(line: 6, column: 22, scope: !28)
!31 = !DILocalVariable(name: "mid", scope: !28, file: !13, line: 6, type: !3)
!32 = !DILocation(line: 0, scope: !28)
!33 = !DILocation(line: 8, column: 13, scope: !34)
!34 = distinct !DILexicalBlock(scope: !28, file: !13, line: 8, column: 13)
!35 = !DILocation(line: 8, column: 20, scope: !34)
!36 = distinct !{!36, !26, !37, !38}
!37 = !DILocation(line: 13, column: 5, scope: !12)
!38 = !{!"llvm.loop.mustprogress"}
!39 = !DILocation(line: 15, column: 12, scope: !40)
!40 = distinct !DILexicalBlock(scope: !12, file: !13, line: 15, column: 9)
!41 = !DILocation(line: 15, column: 16, scope: !40)
!42 = !DILocation(line: 15, column: 19, scope: !40)
!43 = !DILocation(line: 15, column: 25, scope: !40)
!44 = !DILocation(line: 19, column: 5, scope: !12)
!45 = !DILocation(line: 20, column: 1, scope: !12)
