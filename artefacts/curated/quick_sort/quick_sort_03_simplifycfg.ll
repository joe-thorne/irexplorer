; ModuleID = '/workspace/artefacts/curated/quick_sort/quick_sort_02_instcombine.ll'
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
  br label %for.cond, !dbg !47

for.cond:                                         ; preds = %for.inc, %entry
  %i.0 = phi i32 [ %sub, %entry ], [ %i.1, %for.inc ], !dbg !37
  %j.0 = phi i32 [ %low, %entry ], [ %inc12, %for.inc ], !dbg !48
    #dbg_value(i32 %j.0, !44, !DIExpression(), !46)
    #dbg_value(i32 %i.0, !43, !DIExpression(), !37)
  %cmp = icmp slt i32 %j.0, %high, !dbg !49
  br i1 %cmp, label %for.body, label %for.end, !dbg !51

for.body:                                         ; preds = %for.cond
  %idxprom1 = sext i32 %j.0 to i64, !dbg !52
  %arrayidx2 = getelementptr inbounds i32, ptr %a, i64 %idxprom1, !dbg !52
  %1 = load i32, ptr %arrayidx2, align 4, !dbg !52
  %cmp3.not = icmp sgt i32 %1, %0, !dbg !55
  br i1 %cmp3.not, label %for.inc, label %if.then, !dbg !55

if.then:                                          ; preds = %for.body
  %inc = add nsw i32 %i.0, 1, !dbg !56
    #dbg_value(i32 %inc, !43, !DIExpression(), !37)
  %idxprom4 = sext i32 %inc to i64, !dbg !58
  %arrayidx5 = getelementptr inbounds i32, ptr %a, i64 %idxprom4, !dbg !58
  %2 = load i32, ptr %arrayidx5, align 4, !dbg !58
    #dbg_value(i32 %2, !59, !DIExpression(), !60)
  %idxprom6 = sext i32 %j.0 to i64, !dbg !61
  %arrayidx7 = getelementptr inbounds i32, ptr %a, i64 %idxprom6, !dbg !61
  %3 = load i32, ptr %arrayidx7, align 4, !dbg !61
  %idxprom8 = sext i32 %inc to i64, !dbg !62
  %arrayidx9 = getelementptr inbounds i32, ptr %a, i64 %idxprom8, !dbg !62
  store i32 %3, ptr %arrayidx9, align 4, !dbg !63
  %idxprom10 = sext i32 %j.0 to i64, !dbg !64
  %arrayidx11 = getelementptr inbounds i32, ptr %a, i64 %idxprom10, !dbg !64
  store i32 %2, ptr %arrayidx11, align 4, !dbg !65
  br label %for.inc, !dbg !66

for.inc:                                          ; preds = %for.body, %if.then
  %i.1 = phi i32 [ %inc, %if.then ], [ %i.0, %for.body ], !dbg !37
    #dbg_value(i32 %i.1, !43, !DIExpression(), !37)
  %inc12 = add nsw i32 %j.0, 1, !dbg !67
    #dbg_value(i32 %inc12, !44, !DIExpression(), !46)
  br label %for.cond, !dbg !68, !llvm.loop !69

for.end:                                          ; preds = %for.cond
  %4 = sext i32 %i.0 to i64, !dbg !72
  %5 = getelementptr i32, ptr %a, i64 %4, !dbg !72
  %arrayidx15 = getelementptr i8, ptr %5, i64 4, !dbg !72
  %6 = load i32, ptr %arrayidx15, align 4, !dbg !72
    #dbg_value(i32 %6, !73, !DIExpression(), !37)
  %idxprom16 = sext i32 %high to i64, !dbg !74
  %arrayidx17 = getelementptr inbounds i32, ptr %a, i64 %idxprom16, !dbg !74
  %7 = load i32, ptr %arrayidx17, align 4, !dbg !74
  %8 = sext i32 %i.0 to i64, !dbg !75
  %9 = getelementptr i32, ptr %a, i64 %8, !dbg !75
  %arrayidx20 = getelementptr i8, ptr %9, i64 4, !dbg !75
  store i32 %7, ptr %arrayidx20, align 4, !dbg !76
  %idxprom21 = sext i32 %high to i64, !dbg !77
  %arrayidx22 = getelementptr inbounds i32, ptr %a, i64 %idxprom21, !dbg !77
  store i32 %6, ptr %arrayidx22, align 4, !dbg !78
  %add23 = add nsw i32 %i.0, 1, !dbg !79
  ret i32 %add23, !dbg !80
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
!47 = !DILocation(line: 7, column: 10, scope: !45)
!48 = !DILocation(line: 7, scope: !45)
!49 = !DILocation(line: 7, column: 25, scope: !50)
!50 = distinct !DILexicalBlock(scope: !45, file: !11, line: 7, column: 5)
!51 = !DILocation(line: 7, column: 5, scope: !45)
!52 = !DILocation(line: 8, column: 13, scope: !53)
!53 = distinct !DILexicalBlock(scope: !54, file: !11, line: 8, column: 13)
!54 = distinct !DILexicalBlock(scope: !50, file: !11, line: 7, column: 38)
!55 = !DILocation(line: 8, column: 18, scope: !53)
!56 = !DILocation(line: 9, column: 13, scope: !57)
!57 = distinct !DILexicalBlock(scope: !53, file: !11, line: 8, column: 28)
!58 = !DILocation(line: 11, column: 23, scope: !57)
!59 = !DILocalVariable(name: "tmp", scope: !57, file: !11, line: 11, type: !15)
!60 = !DILocation(line: 0, scope: !57)
!61 = !DILocation(line: 12, column: 20, scope: !57)
!62 = !DILocation(line: 12, column: 13, scope: !57)
!63 = !DILocation(line: 12, column: 18, scope: !57)
!64 = !DILocation(line: 13, column: 13, scope: !57)
!65 = !DILocation(line: 13, column: 18, scope: !57)
!66 = !DILocation(line: 14, column: 9, scope: !57)
!67 = !DILocation(line: 7, column: 33, scope: !50)
!68 = !DILocation(line: 7, column: 5, scope: !50)
!69 = distinct !{!69, !51, !70, !71}
!70 = !DILocation(line: 15, column: 5, scope: !45)
!71 = !{!"llvm.loop.mustprogress"}
!72 = !DILocation(line: 17, column: 15, scope: !33)
!73 = !DILocalVariable(name: "tmp", scope: !33, file: !11, line: 17, type: !15)
!74 = !DILocation(line: 18, column: 16, scope: !33)
!75 = !DILocation(line: 18, column: 5, scope: !33)
!76 = !DILocation(line: 18, column: 14, scope: !33)
!77 = !DILocation(line: 19, column: 5, scope: !33)
!78 = !DILocation(line: 19, column: 13, scope: !33)
!79 = !DILocation(line: 21, column: 14, scope: !33)
!80 = !DILocation(line: 21, column: 5, scope: !33)
