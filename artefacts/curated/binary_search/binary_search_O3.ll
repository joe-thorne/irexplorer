; ModuleID = '/workspace/examples/curated/binary_search.c'
source_filename = "/workspace/examples/curated/binary_search.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local range(i32 -1, 2147483647) i32 @binary_search(ptr noundef readonly captures(none) %a, i32 noundef %n, i32 noundef %key) local_unnamed_addr #0 !dbg !16 {
entry:
    #dbg_value(ptr %a, !23, !DIExpression(), !30)
    #dbg_value(i32 %n, !24, !DIExpression(), !30)
    #dbg_value(i32 %key, !25, !DIExpression(), !30)
    #dbg_value(i32 0, !26, !DIExpression(), !30)
    #dbg_value(i32 %n, !27, !DIExpression(), !30)
  %cmp22 = icmp sgt i32 %n, 0, !dbg !31
  br i1 %cmp22, label %while.body, label %while.end, !dbg !32

while.body:                                       ; preds = %entry, %while.body
  %hi.024 = phi i32 [ %hi.1, %while.body ], [ %n, %entry ]
  %lo.023 = phi i32 [ %lo.1, %while.body ], [ 0, %entry ]
    #dbg_value(i32 %hi.024, !27, !DIExpression(), !30)
    #dbg_value(i32 %lo.023, !26, !DIExpression(), !30)
  %sub = sub nsw i32 %hi.024, %lo.023, !dbg !33
  %div21 = lshr i32 %sub, 1, !dbg !34
  %add = add nuw nsw i32 %div21, %lo.023, !dbg !35
    #dbg_value(i32 %add, !28, !DIExpression(), !36)
  %idxprom = zext nneg i32 %add to i64, !dbg !37
  %arrayidx = getelementptr inbounds nuw i32, ptr %a, i64 %idxprom, !dbg !37
  %0 = load i32, ptr %arrayidx, align 4, !dbg !37, !tbaa !12
  %cmp1 = icmp slt i32 %0, %key, !dbg !39
  %add2 = add nuw nsw i32 %add, 1, !dbg !40
  %lo.1 = select i1 %cmp1, i32 %add2, i32 %lo.023, !dbg !40
  %hi.1 = select i1 %cmp1, i32 %hi.024, i32 %add, !dbg !40
    #dbg_value(i32 %hi.1, !27, !DIExpression(), !30)
    #dbg_value(i32 %lo.1, !26, !DIExpression(), !30)
  %cmp = icmp slt i32 %lo.1, %hi.1, !dbg !41
  br i1 %cmp, label %while.body, label %while.end, !dbg !42, !llvm.loop !43

while.end:                                        ; preds = %while.body, %entry
  %lo.0.lcssa = phi i32 [ 0, %entry ], [ %lo.1, %while.body ], !dbg !30
  %cmp3 = icmp slt i32 %lo.0.lcssa, %n, !dbg !47
  br i1 %cmp3, label %land.lhs.true, label %if.end8, !dbg !49

land.lhs.true:                                    ; preds = %while.end
  %idxprom4 = zext nneg i32 %lo.0.lcssa to i64, !dbg !50
  %arrayidx5 = getelementptr inbounds nuw i32, ptr %a, i64 %idxprom4, !dbg !50
  %1 = load i32, ptr %arrayidx5, align 4, !dbg !50, !tbaa !12
  %cmp6 = icmp eq i32 %1, %key, !dbg !51
  br i1 %cmp6, label %cleanup, label %if.end8, !dbg !52

if.end8:                                          ; preds = %land.lhs.true, %while.end
  br label %cleanup, !dbg !53

cleanup:                                          ; preds = %land.lhs.true, %if.end8
  %retval.0 = phi i32 [ -1, %if.end8 ], [ %lo.0.lcssa, %land.lhs.true ], !dbg !30
  ret i32 %retval.0, !dbg !54
}

attributes #0 = { nofree norecurse nosync nounwind memory(argmem: read) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!4, !5, !6, !7, !8, !9, !10}
!llvm.ident = !{!11}
!llvm.errno.tbaa = !{!12}

!0 = distinct !DICompileUnit(language: DW_LANG_C11, file: !1, producer: "clang version 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, retainedTypes: !2, splitDebugInlining: false, nameTableKind: None)
!1 = !DIFile(filename: "/workspace/examples/curated/binary_search.c", directory: "/workspace", checksumkind: CSK_MD5, checksum: "0b3f215bd3150ba37f1d3f81c36b6227")
!2 = !{!3}
!3 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!4 = !{i32 7, !"Dwarf Version", i32 5}
!5 = !{i32 2, !"Debug Info Version", i32 3}
!6 = !{i32 1, !"wchar_size", i32 4}
!7 = !{i32 8, !"PIC Level", i32 2}
!8 = !{i32 7, !"PIE Level", i32 2}
!9 = !{i32 7, !"uwtable", i32 2}
!10 = !{i32 7, !"debug-info-assignment-tracking", i1 true}
!11 = !{!"clang version 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)"}
!12 = !{!13, !13, i64 0}
!13 = !{!"int", !14, i64 0}
!14 = !{!"omnipotent char", !15, i64 0}
!15 = !{!"Simple C/C++ TBAA"}
!16 = distinct !DISubprogram(name: "binary_search", scope: !17, file: !17, line: 1, type: !18, scopeLine: 1, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !22, keyInstructions: true)
!17 = !DIFile(filename: "examples/curated/binary_search.c", directory: "/workspace", checksumkind: CSK_MD5, checksum: "0b3f215bd3150ba37f1d3f81c36b6227")
!18 = !DISubroutineType(types: !19)
!19 = !{!3, !20, !3, !3}
!20 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !21, size: 64)
!21 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !3)
!22 = !{!23, !24, !25, !26, !27, !28}
!23 = !DILocalVariable(name: "a", arg: 1, scope: !16, file: !17, line: 1, type: !20)
!24 = !DILocalVariable(name: "n", arg: 2, scope: !16, file: !17, line: 1, type: !3)
!25 = !DILocalVariable(name: "key", arg: 3, scope: !16, file: !17, line: 1, type: !3)
!26 = !DILocalVariable(name: "lo", scope: !16, file: !17, line: 2, type: !3)
!27 = !DILocalVariable(name: "hi", scope: !16, file: !17, line: 3, type: !3)
!28 = !DILocalVariable(name: "mid", scope: !29, file: !17, line: 6, type: !3)
!29 = distinct !DILexicalBlock(scope: !16, file: !17, line: 5, column: 21)
!30 = !DILocation(line: 0, scope: !16)
!31 = !DILocation(line: 5, column: 15, scope: !16, atomGroup: 14, atomRank: 1)
!32 = !DILocation(line: 5, column: 5, scope: !16, atomGroup: 15, atomRank: 1)
!33 = !DILocation(line: 6, column: 28, scope: !29)
!34 = !DILocation(line: 6, column: 34, scope: !29)
!35 = !DILocation(line: 6, column: 22, scope: !29, atomGroup: 5, atomRank: 2)
!36 = !DILocation(line: 0, scope: !29)
!37 = !DILocation(line: 8, column: 13, scope: !38)
!38 = distinct !DILexicalBlock(scope: !29, file: !17, line: 8, column: 13)
!39 = !DILocation(line: 8, column: 20, scope: !38, atomGroup: 6, atomRank: 2)
!40 = !DILocation(line: 8, column: 20, scope: !38, atomGroup: 6, atomRank: 1)
!41 = !DILocation(line: 5, column: 15, scope: !16, atomGroup: 3, atomRank: 1)
!42 = !DILocation(line: 5, column: 5, scope: !16, atomGroup: 4, atomRank: 1)
!43 = distinct !{!43, !44, !45, !46}
!44 = !DILocation(line: 5, column: 5, scope: !16)
!45 = !DILocation(line: 13, column: 5, scope: !16)
!46 = !{!"llvm.loop.mustprogress"}
!47 = !DILocation(line: 15, column: 12, scope: !48, atomGroup: 9, atomRank: 2)
!48 = distinct !DILexicalBlock(scope: !16, file: !17, line: 15, column: 9)
!49 = !DILocation(line: 15, column: 16, scope: !48, atomGroup: 9, atomRank: 1)
!50 = !DILocation(line: 15, column: 19, scope: !48)
!51 = !DILocation(line: 15, column: 25, scope: !48, atomGroup: 10, atomRank: 2)
!52 = !DILocation(line: 15, column: 16, scope: !48, atomGroup: 10, atomRank: 1)
!53 = !DILocation(line: 19, column: 5, scope: !16, atomGroup: 12, atomRank: 1)
!54 = !DILocation(line: 20, column: 1, scope: !16, atomGroup: 13, atomRank: 1)
