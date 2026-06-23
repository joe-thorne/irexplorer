; ModuleID = '/workspace/artifacts/curated/quick_sort/quick_sort_08_licm.ll'
source_filename = "/workspace/examples/curated/quick_sort.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; Function Attrs: noinline nounwind uwtable
define dso_local void @quick_sort(ptr noundef %a, i32 noundef %low, i32 noundef %high) #0 !dbg !10 {
entry:
    #dbg_value(ptr %a, !17, !DIExpression(), !18)
    #dbg_value(i32 %low, !19, !DIExpression(), !18)
    #dbg_value(i32 %high, !20, !DIExpression(), !18)
  %cmp = icmp slt i32 %low, %high, !dbg !21
  br i1 %cmp, label %if.then, label %if.end, !dbg !21

if.then:                                          ; preds = %entry
  %call = call i32 @partition(ptr noundef %a, i32 noundef %low, i32 noundef %high), !dbg !23
    #dbg_value(i32 %call, !25, !DIExpression(), !26)
  %sub = add nsw i32 %call, -1, !dbg !27
  call void @quick_sort(ptr noundef %a, i32 noundef %low, i32 noundef %sub), !dbg !28
  %add = add nsw i32 %call, 1, !dbg !29
  call void @quick_sort(ptr noundef %a, i32 noundef %add, i32 noundef %high), !dbg !30
  br label %if.end, !dbg !31

if.end:                                           ; preds = %if.then, %entry
  ret void, !dbg !32
}

; Function Attrs: noinline nounwind uwtable
define internal i32 @partition(ptr noundef %a, i32 noundef %low, i32 noundef %high) #0 !dbg !33 {
entry:
    #dbg_value(ptr %a, !36, !DIExpression(), !37)
    #dbg_value(i32 %low, !38, !DIExpression(), !37)
    #dbg_value(i32 %high, !39, !DIExpression(), !37)
  %idxprom = sext i32 %high to i64, !dbg !40
  %arrayidx = getelementptr inbounds i32, ptr %a, i64 %idxprom, !dbg !40
  %0 = load i32, ptr %arrayidx, align 4, !dbg !40
    #dbg_value(i32 %0, !41, !DIExpression(), !37)
  %sub = add nsw i32 %low, -1, !dbg !42
    #dbg_value(i32 %sub, !43, !DIExpression(), !37)
    #dbg_value(i32 %low, !44, !DIExpression(), !46)
  %cmp1 = icmp slt i32 %low, %high, !dbg !47
  br i1 %cmp1, label %for.body.lr.ph, label %for.end, !dbg !49

for.body.lr.ph:                                   ; preds = %entry
  %1 = sext i32 %low to i64, !dbg !49
  %wide.trip.count = sext i32 %high to i64, !dbg !47
  br label %for.body, !dbg !49

for.body:                                         ; preds = %for.inc, %for.body.lr.ph
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ %1, %for.body.lr.ph ]
  %i.02 = phi i32 [ %sub, %for.body.lr.ph ], [ %i.1, %for.inc ]
    #dbg_value(i64 %indvars.iv, !44, !DIExpression(), !46)
    #dbg_value(i32 %i.02, !43, !DIExpression(), !37)
  %arrayidx2 = getelementptr inbounds i32, ptr %a, i64 %indvars.iv, !dbg !50
  %2 = load i32, ptr %arrayidx2, align 4, !dbg !50
  %cmp3.not = icmp sgt i32 %2, %0, !dbg !53
  br i1 %cmp3.not, label %for.inc, label %if.then, !dbg !53

if.then:                                          ; preds = %for.body
  %inc = add nsw i32 %i.02, 1, !dbg !54
    #dbg_value(i32 %inc, !43, !DIExpression(), !37)
  %idxprom4 = sext i32 %inc to i64, !dbg !56
  %arrayidx5 = getelementptr inbounds i32, ptr %a, i64 %idxprom4, !dbg !56
  %3 = load i32, ptr %arrayidx5, align 4, !dbg !56
    #dbg_value(i32 %3, !57, !DIExpression(), !58)
  store i32 %2, ptr %arrayidx5, align 4, !dbg !59
  store i32 %3, ptr %arrayidx2, align 4, !dbg !60
  br label %for.inc, !dbg !61

for.inc:                                          ; preds = %if.then, %for.body
  %i.1 = phi i32 [ %inc, %if.then ], [ %i.02, %for.body ], !dbg !37
    #dbg_value(i32 %i.1, !43, !DIExpression(), !37)
  %indvars.iv.next = add nsw i64 %indvars.iv, 1, !dbg !62
    #dbg_value(i64 %indvars.iv.next, !44, !DIExpression(), !46)
  %exitcond = icmp ne i64 %indvars.iv.next, %wide.trip.count, !dbg !47
  br i1 %exitcond, label %for.body, label %for.cond.for.end_crit_edge, !dbg !49, !llvm.loop !63

for.cond.for.end_crit_edge:                       ; preds = %for.inc
  %split = phi i32 [ %i.1, %for.inc ]
  br label %for.end, !dbg !49

for.end:                                          ; preds = %for.cond.for.end_crit_edge, %entry
  %i.0.lcssa = phi i32 [ %split, %for.cond.for.end_crit_edge ], [ %sub, %entry ], !dbg !37
  %4 = sext i32 %i.0.lcssa to i64, !dbg !66
  %5 = getelementptr i32, ptr %a, i64 %4, !dbg !66
  %arrayidx15 = getelementptr i8, ptr %5, i64 4, !dbg !66
  %6 = load i32, ptr %arrayidx15, align 4, !dbg !66
    #dbg_value(i32 %6, !67, !DIExpression(), !37)
  %7 = load i32, ptr %arrayidx, align 4, !dbg !68
  store i32 %7, ptr %arrayidx15, align 4, !dbg !69
  store i32 %6, ptr %arrayidx, align 4, !dbg !70
  %add23 = add nsw i32 %i.0.lcssa, 1, !dbg !71
  ret i32 %add23, !dbg !72
}

attributes #0 = { noinline nounwind uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!2, !3, !4, !5, !6, !7, !8}
!llvm.ident = !{!9}

!0 = distinct !DICompileUnit(language: DW_LANG_C11, file: !1, producer: "clang version 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, splitDebugInlining: false, nameTableKind: None)
!1 = !DIFile(filename: "/workspace/examples/curated/quick_sort.c", directory: "/workspace", checksumkind: CSK_MD5, checksum: "5efe0dbb3421cb59fd9034792cd513b7")
!2 = !{i32 7, !"Dwarf Version", i32 5}
!3 = !{i32 2, !"Debug Info Version", i32 3}
!4 = !{i32 1, !"wchar_size", i32 4}
!5 = !{i32 8, !"PIC Level", i32 2}
!6 = !{i32 7, !"PIE Level", i32 2}
!7 = !{i32 7, !"uwtable", i32 2}
!8 = !{i32 7, !"frame-pointer", i32 2}
!9 = !{!"clang version 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)"}
!10 = distinct !DISubprogram(name: "quick_sort", scope: !11, file: !11, line: 24, type: !12, scopeLine: 24, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !16)
!11 = !DIFile(filename: "examples/curated/quick_sort.c", directory: "/workspace", checksumkind: CSK_MD5, checksum: "5efe0dbb3421cb59fd9034792cd513b7")
!12 = !DISubroutineType(types: !13)
!13 = !{null, !14, !15, !15}
!14 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !15, size: 64)
!15 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!16 = !{}
!17 = !DILocalVariable(name: "a", arg: 1, scope: !10, file: !11, line: 24, type: !14)
!18 = !DILocation(line: 0, scope: !10)
!19 = !DILocalVariable(name: "low", arg: 2, scope: !10, file: !11, line: 24, type: !15)
!20 = !DILocalVariable(name: "high", arg: 3, scope: !10, file: !11, line: 24, type: !15)
!21 = !DILocation(line: 25, column: 13, scope: !22)
!22 = distinct !DILexicalBlock(scope: !10, file: !11, line: 25, column: 9)
!23 = !DILocation(line: 26, column: 17, scope: !24)
!24 = distinct !DILexicalBlock(scope: !22, file: !11, line: 25, column: 21)
!25 = !DILocalVariable(name: "p", scope: !24, file: !11, line: 26, type: !15)
!26 = !DILocation(line: 0, scope: !24)
!27 = !DILocation(line: 28, column: 30, scope: !24)
!28 = !DILocation(line: 28, column: 9, scope: !24)
!29 = !DILocation(line: 29, column: 25, scope: !24)
!30 = !DILocation(line: 29, column: 9, scope: !24)
!31 = !DILocation(line: 30, column: 5, scope: !24)
!32 = !DILocation(line: 31, column: 1, scope: !10)
!33 = distinct !DISubprogram(name: "partition", scope: !11, file: !11, line: 3, type: !34, scopeLine: 3, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !0, retainedNodes: !16)
!34 = !DISubroutineType(types: !35)
!35 = !{!15, !14, !15, !15}
!36 = !DILocalVariable(name: "a", arg: 1, scope: !33, file: !11, line: 3, type: !14)
!37 = !DILocation(line: 0, scope: !33)
!38 = !DILocalVariable(name: "low", arg: 2, scope: !33, file: !11, line: 3, type: !15)
!39 = !DILocalVariable(name: "high", arg: 3, scope: !33, file: !11, line: 3, type: !15)
!40 = !DILocation(line: 4, column: 17, scope: !33)
!41 = !DILocalVariable(name: "pivot", scope: !33, file: !11, line: 4, type: !15)
!42 = !DILocation(line: 5, column: 17, scope: !33)
!43 = !DILocalVariable(name: "i", scope: !33, file: !11, line: 5, type: !15)
!44 = !DILocalVariable(name: "j", scope: !45, file: !11, line: 7, type: !15)
!45 = distinct !DILexicalBlock(scope: !33, file: !11, line: 7, column: 5)
!46 = !DILocation(line: 0, scope: !45)
!47 = !DILocation(line: 7, column: 25, scope: !48)
!48 = distinct !DILexicalBlock(scope: !45, file: !11, line: 7, column: 5)
!49 = !DILocation(line: 7, column: 5, scope: !45)
!50 = !DILocation(line: 8, column: 13, scope: !51)
!51 = distinct !DILexicalBlock(scope: !52, file: !11, line: 8, column: 13)
!52 = distinct !DILexicalBlock(scope: !48, file: !11, line: 7, column: 38)
!53 = !DILocation(line: 8, column: 18, scope: !51)
!54 = !DILocation(line: 9, column: 13, scope: !55)
!55 = distinct !DILexicalBlock(scope: !51, file: !11, line: 8, column: 28)
!56 = !DILocation(line: 11, column: 23, scope: !55)
!57 = !DILocalVariable(name: "tmp", scope: !55, file: !11, line: 11, type: !15)
!58 = !DILocation(line: 0, scope: !55)
!59 = !DILocation(line: 12, column: 18, scope: !55)
!60 = !DILocation(line: 13, column: 18, scope: !55)
!61 = !DILocation(line: 14, column: 9, scope: !55)
!62 = !DILocation(line: 7, column: 33, scope: !48)
!63 = distinct !{!63, !49, !64, !65}
!64 = !DILocation(line: 15, column: 5, scope: !45)
!65 = !{!"llvm.loop.mustprogress"}
!66 = !DILocation(line: 17, column: 15, scope: !33)
!67 = !DILocalVariable(name: "tmp", scope: !33, file: !11, line: 17, type: !15)
!68 = !DILocation(line: 18, column: 16, scope: !33)
!69 = !DILocation(line: 18, column: 14, scope: !33)
!70 = !DILocation(line: 19, column: 13, scope: !33)
!71 = !DILocation(line: 21, column: 14, scope: !33)
!72 = !DILocation(line: 21, column: 5, scope: !33)
