; ModuleID = '/workspace/artefacts/curated/binary_search/binary_search_05_cleanup.ll'
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
  br label %while.cond, !dbg !25

while.cond:                                       ; preds = %while.body, %entry
  %lo.0 = phi i32 [ 0, %entry ], [ %lo.1, %while.body ], !dbg !20
  %hi.0 = phi i32 [ %n, %entry ], [ %hi.1, %while.body ], !dbg !26
    #dbg_value(i32 %hi.0, !24, !DIExpression(), !20)
    #dbg_value(i32 %lo.0, !23, !DIExpression(), !20)
  %cmp = icmp slt i32 %lo.0, %hi.0, !dbg !27
  br i1 %cmp, label %while.body, label %while.end, !dbg !25

while.body:                                       ; preds = %while.cond
  %sub = sub nsw i32 %hi.0, %lo.0, !dbg !28
  %div1 = lshr i32 %sub, 1, !dbg !30
  %add = add nsw i32 %lo.0, %div1, !dbg !31
    #dbg_value(i32 %add, !32, !DIExpression(), !33)
  %idxprom = sext i32 %add to i64, !dbg !34
  %arrayidx = getelementptr inbounds i32, ptr %a, i64 %idxprom, !dbg !34
  %0 = load i32, ptr %arrayidx, align 4, !dbg !34
  %cmp1 = icmp slt i32 %0, %key, !dbg !36
  %add2 = add nsw i32 %add, 1, !dbg !36
  %lo.1 = select i1 %cmp1, i32 %add2, i32 %lo.0, !dbg !36
  %hi.1 = select i1 %cmp1, i32 %hi.0, i32 %add, !dbg !36
    #dbg_value(i32 %hi.1, !24, !DIExpression(), !20)
    #dbg_value(i32 %lo.1, !23, !DIExpression(), !20)
  br label %while.cond, !dbg !25, !llvm.loop !37

while.end:                                        ; preds = %while.cond
  %lo.0.lcssa = phi i32 [ %lo.0, %while.cond ], !dbg !20
  %cmp3 = icmp slt i32 %lo.0.lcssa, %n, !dbg !40
  br i1 %cmp3, label %land.lhs.true, label %if.end8, !dbg !42

land.lhs.true:                                    ; preds = %while.end
  %idxprom4 = sext i32 %lo.0.lcssa to i64, !dbg !43
  %arrayidx5 = getelementptr inbounds i32, ptr %a, i64 %idxprom4, !dbg !43
  %1 = load i32, ptr %arrayidx5, align 4, !dbg !43
  %cmp6 = icmp eq i32 %1, %key, !dbg !44
  br i1 %cmp6, label %return, label %if.end8, !dbg !42

if.end8:                                          ; preds = %land.lhs.true, %while.end
  br label %return, !dbg !45

return:                                           ; preds = %if.end8, %land.lhs.true
  %retval.0 = phi i32 [ -1, %if.end8 ], [ %lo.0.lcssa, %land.lhs.true ], !dbg !20
  ret i32 %retval.0, !dbg !46
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
!25 = !DILocation(line: 5, column: 5, scope: !12)
!26 = !DILocation(line: 3, column: 9, scope: !12)
!27 = !DILocation(line: 5, column: 15, scope: !12)
!28 = !DILocation(line: 6, column: 28, scope: !29)
!29 = distinct !DILexicalBlock(scope: !12, file: !13, line: 5, column: 21)
!30 = !DILocation(line: 6, column: 34, scope: !29)
!31 = !DILocation(line: 6, column: 22, scope: !29)
!32 = !DILocalVariable(name: "mid", scope: !29, file: !13, line: 6, type: !3)
!33 = !DILocation(line: 0, scope: !29)
!34 = !DILocation(line: 8, column: 13, scope: !35)
!35 = distinct !DILexicalBlock(scope: !29, file: !13, line: 8, column: 13)
!36 = !DILocation(line: 8, column: 20, scope: !35)
!37 = distinct !{!37, !25, !38, !39}
!38 = !DILocation(line: 13, column: 5, scope: !12)
!39 = !{!"llvm.loop.mustprogress"}
!40 = !DILocation(line: 15, column: 12, scope: !41)
!41 = distinct !DILexicalBlock(scope: !12, file: !13, line: 15, column: 9)
!42 = !DILocation(line: 15, column: 16, scope: !41)
!43 = !DILocation(line: 15, column: 19, scope: !41)
!44 = !DILocation(line: 15, column: 25, scope: !41)
!45 = !DILocation(line: 19, column: 5, scope: !12)
!46 = !DILocation(line: 20, column: 1, scope: !12)
