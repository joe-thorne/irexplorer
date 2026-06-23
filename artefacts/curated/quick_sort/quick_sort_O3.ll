; ModuleID = '/workspace/examples/curated/quick_sort.c'
source_filename = "/workspace/examples/curated/quick_sort.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; Function Attrs: nofree nosync nounwind memory(argmem: readwrite) uwtable
define dso_local void @quick_sort(ptr noundef captures(none) %a, i32 noundef %low, i32 noundef %high) local_unnamed_addr #0 !dbg !14 {
entry:
    #dbg_value(ptr %a, !21, !DIExpression(), !27)
    #dbg_value(i32 %low, !22, !DIExpression(), !27)
    #dbg_value(i32 %high, !23, !DIExpression(), !27)
  %cmp8 = icmp slt i32 %low, %high, !dbg !28
  br i1 %cmp8, label %for.body.preheader.i.lr.ph, label %if.end, !dbg !29

for.body.preheader.i.lr.ph:                       ; preds = %entry
  %idxprom.i = sext i32 %high to i64
  %arrayidx.i = getelementptr inbounds i32, ptr %a, i64 %idxprom.i
  %0 = add nsw i64 %idxprom.i, -1
  br label %for.body.preheader.i, !dbg !29

for.body.preheader.i:                             ; preds = %for.body.preheader.i.lr.ph, %partition.exit
  %low.tr9 = phi i32 [ %low, %for.body.preheader.i.lr.ph ], [ %add, %partition.exit ]
    #dbg_value(i32 %low.tr9, !22, !DIExpression(), !27)
    #dbg_value(ptr %a, !30, !DIExpression(), !47)
    #dbg_value(i32 %low.tr9, !35, !DIExpression(), !47)
    #dbg_value(i32 %high, !36, !DIExpression(), !47)
  %1 = load i32, ptr %arrayidx.i, align 4, !dbg !49, !tbaa !10
    #dbg_value(i32 %1, !37, !DIExpression(), !47)
    #dbg_value(i32 %low.tr9, !38, !DIExpression(DW_OP_constu, 1, DW_OP_minus, DW_OP_stack_value), !47)
    #dbg_value(i32 %low.tr9, !39, !DIExpression(), !50)
  %sub.i = add nsw i32 %low.tr9, -1, !dbg !51
    #dbg_value(i32 %sub.i, !38, !DIExpression(), !47)
  %2 = sext i32 %low.tr9 to i64, !dbg !52
  %3 = sub nsw i64 %idxprom.i, %2, !dbg !52
  %xtraiter = and i64 %3, 1, !dbg !52
  %lcmp.mod.not = icmp eq i64 %xtraiter, 0, !dbg !52
  br i1 %lcmp.mod.not, label %for.body.i.prol.loopexit, label %for.body.i.prol, !dbg !52

for.body.i.prol:                                  ; preds = %for.body.preheader.i
    #dbg_value(i32 %sub.i, !38, !DIExpression(), !47)
    #dbg_value(i64 %2, !39, !DIExpression(), !50)
  %arrayidx2.i.prol = getelementptr inbounds i32, ptr %a, i64 %2, !dbg !53
  %4 = load i32, ptr %arrayidx2.i.prol, align 4, !dbg !53, !tbaa !10
  %cmp3.not.i.prol = icmp sgt i32 %4, %1, !dbg !54
  br i1 %cmp3.not.i.prol, label %for.inc.i.prol, label %if.then.i.prol, !dbg !55

if.then.i.prol:                                   ; preds = %for.body.i.prol
    #dbg_value(i32 %low.tr9, !38, !DIExpression(), !47)
  %idxprom4.i.prol = sext i32 %low.tr9 to i64, !dbg !56
  %arrayidx5.i.prol = getelementptr inbounds i32, ptr %a, i64 %idxprom4.i.prol, !dbg !56
  %5 = load i32, ptr %arrayidx5.i.prol, align 4, !dbg !57, !tbaa !10
    #dbg_value(i32 %5, !41, !DIExpression(), !58)
  store i32 %4, ptr %arrayidx5.i.prol, align 4, !dbg !59, !tbaa !10
  store i32 %5, ptr %arrayidx2.i.prol, align 4, !dbg !60, !tbaa !10
  br label %for.inc.i.prol, !dbg !61

for.inc.i.prol:                                   ; preds = %if.then.i.prol, %for.body.i.prol
  %i.1.i.prol = phi i32 [ %low.tr9, %if.then.i.prol ], [ %sub.i, %for.body.i.prol ], !dbg !47
    #dbg_value(i32 %i.1.i.prol, !38, !DIExpression(), !47)
  %indvars.iv.next.i.prol = add nsw i64 %2, 1, !dbg !62
    #dbg_value(i64 %indvars.iv.next.i.prol, !39, !DIExpression(), !50)
  br label %for.body.i.prol.loopexit, !dbg !52

for.body.i.prol.loopexit:                         ; preds = %for.inc.i.prol, %for.body.preheader.i
  %i.1.i.lcssa.unr = phi i32 [ poison, %for.body.preheader.i ], [ %i.1.i.prol, %for.inc.i.prol ]
  %indvars.iv.i.unr = phi i64 [ %2, %for.body.preheader.i ], [ %indvars.iv.next.i.prol, %for.inc.i.prol ]
  %i.048.i.unr = phi i32 [ %sub.i, %for.body.preheader.i ], [ %i.1.i.prol, %for.inc.i.prol ]
  %6 = icmp eq i64 %0, %2, !dbg !52
  br i1 %6, label %partition.exit, label %for.body.i, !dbg !52

for.body.i:                                       ; preds = %for.body.i.prol.loopexit, %for.inc.i.1
  %indvars.iv.i = phi i64 [ %indvars.iv.next.i.1, %for.inc.i.1 ], [ %indvars.iv.i.unr, %for.body.i.prol.loopexit ]
  %i.048.i = phi i32 [ %i.1.i.1, %for.inc.i.1 ], [ %i.048.i.unr, %for.body.i.prol.loopexit ]
    #dbg_value(i32 %i.048.i, !38, !DIExpression(), !47)
    #dbg_value(i64 %indvars.iv.i, !39, !DIExpression(), !50)
  %arrayidx2.i = getelementptr inbounds i32, ptr %a, i64 %indvars.iv.i, !dbg !53
  %7 = load i32, ptr %arrayidx2.i, align 4, !dbg !53, !tbaa !10
  %cmp3.not.i = icmp sgt i32 %7, %1, !dbg !63
  br i1 %cmp3.not.i, label %for.inc.i, label %if.then.i, !dbg !64

if.then.i:                                        ; preds = %for.body.i
  %inc.i = add nsw i32 %i.048.i, 1, !dbg !65
    #dbg_value(i32 %inc.i, !38, !DIExpression(), !47)
  %idxprom4.i = sext i32 %inc.i to i64, !dbg !56
  %arrayidx5.i = getelementptr inbounds i32, ptr %a, i64 %idxprom4.i, !dbg !56
  %8 = load i32, ptr %arrayidx5.i, align 4, !dbg !66, !tbaa !10
    #dbg_value(i32 %8, !41, !DIExpression(), !58)
  store i32 %7, ptr %arrayidx5.i, align 4, !dbg !67, !tbaa !10
  store i32 %8, ptr %arrayidx2.i, align 4, !dbg !68, !tbaa !10
  br label %for.inc.i, !dbg !61

for.inc.i:                                        ; preds = %if.then.i, %for.body.i
  %i.1.i = phi i32 [ %inc.i, %if.then.i ], [ %i.048.i, %for.body.i ], !dbg !47
    #dbg_value(i32 %i.1.i, !38, !DIExpression(), !47)
    #dbg_value(i64 %indvars.iv.i, !39, !DIExpression(DW_OP_plus_uconst, 1, DW_OP_stack_value), !50)
  %9 = getelementptr i32, ptr %a, i64 %indvars.iv.i, !dbg !53
  %arrayidx2.i.1 = getelementptr i8, ptr %9, i64 4, !dbg !53
  %10 = load i32, ptr %arrayidx2.i.1, align 4, !dbg !53, !tbaa !10
  %cmp3.not.i.1 = icmp sgt i32 %10, %1, !dbg !69
  br i1 %cmp3.not.i.1, label %for.inc.i.1, label %if.then.i.1, !dbg !70

if.then.i.1:                                      ; preds = %for.inc.i
  %inc.i.1 = add nsw i32 %i.1.i, 1, !dbg !71
    #dbg_value(i32 %inc.i.1, !38, !DIExpression(), !47)
  %idxprom4.i.1 = sext i32 %inc.i.1 to i64, !dbg !56
  %arrayidx5.i.1 = getelementptr inbounds i32, ptr %a, i64 %idxprom4.i.1, !dbg !56
  %11 = load i32, ptr %arrayidx5.i.1, align 4, !dbg !72, !tbaa !10
    #dbg_value(i32 %11, !41, !DIExpression(), !58)
  store i32 %10, ptr %arrayidx5.i.1, align 4, !dbg !73, !tbaa !10
  store i32 %11, ptr %arrayidx2.i.1, align 4, !dbg !74, !tbaa !10
  br label %for.inc.i.1, !dbg !61

for.inc.i.1:                                      ; preds = %if.then.i.1, %for.inc.i
  %i.1.i.1 = phi i32 [ %inc.i.1, %if.then.i.1 ], [ %i.1.i, %for.inc.i ], !dbg !47
    #dbg_value(i32 %i.1.i.1, !38, !DIExpression(), !47)
  %indvars.iv.next.i.1 = add nsw i64 %indvars.iv.i, 2, !dbg !75
    #dbg_value(i64 %indvars.iv.next.i.1, !39, !DIExpression(), !50)
  %exitcond.not.i.1 = icmp eq i64 %indvars.iv.next.i.1, %idxprom.i, !dbg !76
  br i1 %exitcond.not.i.1, label %partition.exit, label %for.body.i, !dbg !77, !llvm.loop !78

partition.exit:                                   ; preds = %for.inc.i.1, %for.body.i.prol.loopexit
  %i.1.i.lcssa = phi i32 [ %i.1.i.lcssa.unr, %for.body.i.prol.loopexit ], [ %i.1.i.1, %for.inc.i.1 ], !dbg !47
  %.pre.i = load i32, ptr %arrayidx.i, align 4, !dbg !81, !tbaa !10
  %12 = sext i32 %i.1.i.lcssa to i64, !dbg !82
  %13 = getelementptr i32, ptr %a, i64 %12, !dbg !82
  %arrayidx15.i = getelementptr i8, ptr %13, i64 4, !dbg !82
  %14 = load i32, ptr %arrayidx15.i, align 4, !dbg !83, !tbaa !10
    #dbg_value(i32 %14, !46, !DIExpression(), !47)
  store i32 %.pre.i, ptr %arrayidx15.i, align 4, !dbg !84, !tbaa !10
  store i32 %14, ptr %arrayidx.i, align 4, !dbg !85, !tbaa !10
    #dbg_value(i32 %i.1.i.lcssa, !24, !DIExpression(DW_OP_plus_uconst, 1, DW_OP_stack_value), !86)
  tail call void @quick_sort(ptr noundef nonnull %a, i32 noundef %low.tr9, i32 noundef %i.1.i.lcssa), !dbg !87
  %add = add nsw i32 %i.1.i.lcssa, 2, !dbg !88
    #dbg_value(ptr %a, !21, !DIExpression(), !27)
    #dbg_value(i32 %add, !22, !DIExpression(), !27)
    #dbg_value(i32 %high, !23, !DIExpression(), !27)
  %cmp = icmp slt i32 %add, %high, !dbg !89
  br i1 %cmp, label %for.body.preheader.i, label %if.end, !dbg !90

if.end:                                           ; preds = %partition.exit, %entry
  ret void, !dbg !91
}

attributes #0 = { nofree nosync nounwind memory(argmem: readwrite) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!2, !3, !4, !5, !6, !7, !8}
!llvm.ident = !{!9}
!llvm.errno.tbaa = !{!10}

!0 = distinct !DICompileUnit(language: DW_LANG_C11, file: !1, producer: "clang version 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, splitDebugInlining: false, nameTableKind: None)
!1 = !DIFile(filename: "/workspace/examples/curated/quick_sort.c", directory: "/workspace", checksumkind: CSK_MD5, checksum: "5efe0dbb3421cb59fd9034792cd513b7")
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
!14 = distinct !DISubprogram(name: "quick_sort", scope: !15, file: !15, line: 24, type: !16, scopeLine: 24, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !20, keyInstructions: true)
!15 = !DIFile(filename: "examples/curated/quick_sort.c", directory: "/workspace", checksumkind: CSK_MD5, checksum: "5efe0dbb3421cb59fd9034792cd513b7")
!16 = !DISubroutineType(types: !17)
!17 = !{null, !18, !19, !19}
!18 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !19, size: 64)
!19 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!20 = !{!21, !22, !23, !24}
!21 = !DILocalVariable(name: "a", arg: 1, scope: !14, file: !15, line: 24, type: !18)
!22 = !DILocalVariable(name: "low", arg: 2, scope: !14, file: !15, line: 24, type: !19)
!23 = !DILocalVariable(name: "high", arg: 3, scope: !14, file: !15, line: 24, type: !19)
!24 = !DILocalVariable(name: "p", scope: !25, file: !15, line: 26, type: !19)
!25 = distinct !DILexicalBlock(scope: !26, file: !15, line: 25, column: 21)
!26 = distinct !DILexicalBlock(scope: !14, file: !15, line: 25, column: 9)
!27 = !DILocation(line: 0, scope: !14)
!28 = !DILocation(line: 25, column: 13, scope: !26, atomGroup: 20, atomRank: 2)
!29 = !DILocation(line: 25, column: 13, scope: !26, atomGroup: 20, atomRank: 1)
!30 = !DILocalVariable(name: "a", arg: 1, scope: !31, file: !15, line: 3, type: !18)
!31 = distinct !DISubprogram(name: "partition", scope: !15, file: !15, line: 3, type: !32, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !34, keyInstructions: true)
!32 = !DISubroutineType(types: !33)
!33 = !{!19, !18, !19, !19}
!34 = !{!30, !35, !36, !37, !38, !39, !41, !46}
!35 = !DILocalVariable(name: "low", arg: 2, scope: !31, file: !15, line: 3, type: !19)
!36 = !DILocalVariable(name: "high", arg: 3, scope: !31, file: !15, line: 3, type: !19)
!37 = !DILocalVariable(name: "pivot", scope: !31, file: !15, line: 4, type: !19)
!38 = !DILocalVariable(name: "i", scope: !31, file: !15, line: 5, type: !19)
!39 = !DILocalVariable(name: "j", scope: !40, file: !15, line: 7, type: !19)
!40 = distinct !DILexicalBlock(scope: !31, file: !15, line: 7, column: 5)
!41 = !DILocalVariable(name: "tmp", scope: !42, file: !15, line: 11, type: !19)
!42 = distinct !DILexicalBlock(scope: !43, file: !15, line: 8, column: 28)
!43 = distinct !DILexicalBlock(scope: !44, file: !15, line: 8, column: 13)
!44 = distinct !DILexicalBlock(scope: !45, file: !15, line: 7, column: 38)
!45 = distinct !DILexicalBlock(scope: !40, file: !15, line: 7, column: 5)
!46 = !DILocalVariable(name: "tmp", scope: !31, file: !15, line: 17, type: !19)
!47 = !DILocation(line: 0, scope: !31, inlinedAt: !48)
!48 = distinct !DILocation(line: 26, column: 17, scope: !25)
!49 = !DILocation(line: 4, column: 17, scope: !31, inlinedAt: !48, atomGroup: 1, atomRank: 2)
!50 = !DILocation(line: 0, scope: !40, inlinedAt: !48)
!51 = !DILocation(line: 5, column: 17, scope: !31, inlinedAt: !48, atomGroup: 2, atomRank: 2)
!52 = !DILocation(line: 7, column: 5, scope: !40, inlinedAt: !48)
!53 = !DILocation(line: 8, column: 13, scope: !43, inlinedAt: !48)
!54 = !DILocation(line: 8, column: 18, scope: !43, inlinedAt: !48, atomGroup: 21, atomRank: 2)
!55 = !DILocation(line: 8, column: 18, scope: !43, inlinedAt: !48, atomGroup: 21, atomRank: 1)
!56 = !DILocation(line: 11, column: 23, scope: !42, inlinedAt: !48)
!57 = !DILocation(line: 11, column: 23, scope: !42, inlinedAt: !48, atomGroup: 23, atomRank: 2)
!58 = !DILocation(line: 0, scope: !42, inlinedAt: !48)
!59 = !DILocation(line: 12, column: 18, scope: !42, inlinedAt: !48, atomGroup: 24, atomRank: 1)
!60 = !DILocation(line: 13, column: 18, scope: !42, inlinedAt: !48, atomGroup: 25, atomRank: 1)
!61 = !DILocation(line: 14, column: 9, scope: !42, inlinedAt: !48)
!62 = !DILocation(line: 7, column: 33, scope: !45, inlinedAt: !48, atomGroup: 26, atomRank: 2)
!63 = !DILocation(line: 8, column: 18, scope: !43, inlinedAt: !48, atomGroup: 6, atomRank: 2)
!64 = !DILocation(line: 8, column: 18, scope: !43, inlinedAt: !48, atomGroup: 6, atomRank: 1)
!65 = !DILocation(line: 9, column: 13, scope: !42, inlinedAt: !48, atomGroup: 7, atomRank: 2)
!66 = !DILocation(line: 11, column: 23, scope: !42, inlinedAt: !48, atomGroup: 8, atomRank: 2)
!67 = !DILocation(line: 12, column: 18, scope: !42, inlinedAt: !48, atomGroup: 9, atomRank: 1)
!68 = !DILocation(line: 13, column: 18, scope: !42, inlinedAt: !48, atomGroup: 10, atomRank: 1)
!69 = !DILocation(line: 8, column: 18, scope: !43, inlinedAt: !48, atomGroup: 29, atomRank: 2)
!70 = !DILocation(line: 8, column: 18, scope: !43, inlinedAt: !48, atomGroup: 29, atomRank: 1)
!71 = !DILocation(line: 9, column: 13, scope: !42, inlinedAt: !48, atomGroup: 30, atomRank: 2)
!72 = !DILocation(line: 11, column: 23, scope: !42, inlinedAt: !48, atomGroup: 31, atomRank: 2)
!73 = !DILocation(line: 12, column: 18, scope: !42, inlinedAt: !48, atomGroup: 32, atomRank: 1)
!74 = !DILocation(line: 13, column: 18, scope: !42, inlinedAt: !48, atomGroup: 33, atomRank: 1)
!75 = !DILocation(line: 7, column: 33, scope: !45, inlinedAt: !48, atomGroup: 34, atomRank: 2)
!76 = !DILocation(line: 7, column: 25, scope: !45, inlinedAt: !48, atomGroup: 35, atomRank: 1)
!77 = !DILocation(line: 7, column: 5, scope: !40, inlinedAt: !48, atomGroup: 36, atomRank: 1)
!78 = distinct !{!78, !52, !79, !80}
!79 = !DILocation(line: 15, column: 5, scope: !40, inlinedAt: !48)
!80 = !{!"llvm.loop.mustprogress"}
!81 = !DILocation(line: 18, column: 16, scope: !31, inlinedAt: !48, atomGroup: 14, atomRank: 2)
!82 = !DILocation(line: 17, column: 15, scope: !31, inlinedAt: !48)
!83 = !DILocation(line: 17, column: 15, scope: !31, inlinedAt: !48, atomGroup: 13, atomRank: 2)
!84 = !DILocation(line: 18, column: 14, scope: !31, inlinedAt: !48, atomGroup: 14, atomRank: 1)
!85 = !DILocation(line: 19, column: 13, scope: !31, inlinedAt: !48, atomGroup: 15, atomRank: 1)
!86 = !DILocation(line: 0, scope: !25)
!87 = !DILocation(line: 28, column: 9, scope: !25)
!88 = !DILocation(line: 29, column: 25, scope: !25)
!89 = !DILocation(line: 25, column: 13, scope: !26, atomGroup: 1, atomRank: 2)
!90 = !DILocation(line: 25, column: 13, scope: !26, atomGroup: 1, atomRank: 1)
!91 = !DILocation(line: 31, column: 1, scope: !14, atomGroup: 3, atomRank: 1)
