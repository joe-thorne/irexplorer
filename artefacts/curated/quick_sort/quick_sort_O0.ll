; ModuleID = '/workspace/examples/curated/quick_sort.c'
source_filename = "/workspace/examples/curated/quick_sort.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; Function Attrs: noinline nounwind uwtable
define dso_local void @quick_sort(ptr noundef %a, i32 noundef %low, i32 noundef %high) #0 !dbg !10 {
entry:
  %a.addr = alloca ptr, align 8
  %low.addr = alloca i32, align 4
  %high.addr = alloca i32, align 4
  %p = alloca i32, align 4
  store ptr %a, ptr %a.addr, align 8
    #dbg_declare(ptr %a.addr, !17, !DIExpression(), !18)
  store i32 %low, ptr %low.addr, align 4
    #dbg_declare(ptr %low.addr, !19, !DIExpression(), !20)
  store i32 %high, ptr %high.addr, align 4
    #dbg_declare(ptr %high.addr, !21, !DIExpression(), !22)
  %0 = load i32, ptr %low.addr, align 4, !dbg !23
  %1 = load i32, ptr %high.addr, align 4, !dbg !25
  %cmp = icmp slt i32 %0, %1, !dbg !26
  br i1 %cmp, label %if.then, label %if.end, !dbg !26

if.then:                                          ; preds = %entry
    #dbg_declare(ptr %p, !27, !DIExpression(), !29)
  %2 = load ptr, ptr %a.addr, align 8, !dbg !30
  %3 = load i32, ptr %low.addr, align 4, !dbg !31
  %4 = load i32, ptr %high.addr, align 4, !dbg !32
  %call = call i32 @partition(ptr noundef %2, i32 noundef %3, i32 noundef %4), !dbg !33
  store i32 %call, ptr %p, align 4, !dbg !29
  %5 = load ptr, ptr %a.addr, align 8, !dbg !34
  %6 = load i32, ptr %low.addr, align 4, !dbg !35
  %7 = load i32, ptr %p, align 4, !dbg !36
  %sub = sub nsw i32 %7, 1, !dbg !37
  call void @quick_sort(ptr noundef %5, i32 noundef %6, i32 noundef %sub), !dbg !38
  %8 = load ptr, ptr %a.addr, align 8, !dbg !39
  %9 = load i32, ptr %p, align 4, !dbg !40
  %add = add nsw i32 %9, 1, !dbg !41
  %10 = load i32, ptr %high.addr, align 4, !dbg !42
  call void @quick_sort(ptr noundef %8, i32 noundef %add, i32 noundef %10), !dbg !43
  br label %if.end, !dbg !44

if.end:                                           ; preds = %if.then, %entry
  ret void, !dbg !45
}

; Function Attrs: noinline nounwind uwtable
define internal i32 @partition(ptr noundef %a, i32 noundef %low, i32 noundef %high) #0 !dbg !46 {
entry:
  %a.addr = alloca ptr, align 8
  %low.addr = alloca i32, align 4
  %high.addr = alloca i32, align 4
  %pivot = alloca i32, align 4
  %i = alloca i32, align 4
  %j = alloca i32, align 4
  %tmp = alloca i32, align 4
  %tmp13 = alloca i32, align 4
  store ptr %a, ptr %a.addr, align 8
    #dbg_declare(ptr %a.addr, !49, !DIExpression(), !50)
  store i32 %low, ptr %low.addr, align 4
    #dbg_declare(ptr %low.addr, !51, !DIExpression(), !52)
  store i32 %high, ptr %high.addr, align 4
    #dbg_declare(ptr %high.addr, !53, !DIExpression(), !54)
    #dbg_declare(ptr %pivot, !55, !DIExpression(), !56)
  %0 = load ptr, ptr %a.addr, align 8, !dbg !57
  %1 = load i32, ptr %high.addr, align 4, !dbg !58
  %idxprom = sext i32 %1 to i64, !dbg !57
  %arrayidx = getelementptr inbounds i32, ptr %0, i64 %idxprom, !dbg !57
  %2 = load i32, ptr %arrayidx, align 4, !dbg !57
  store i32 %2, ptr %pivot, align 4, !dbg !56
    #dbg_declare(ptr %i, !59, !DIExpression(), !60)
  %3 = load i32, ptr %low.addr, align 4, !dbg !61
  %sub = sub nsw i32 %3, 1, !dbg !62
  store i32 %sub, ptr %i, align 4, !dbg !60
    #dbg_declare(ptr %j, !63, !DIExpression(), !65)
  %4 = load i32, ptr %low.addr, align 4, !dbg !66
  store i32 %4, ptr %j, align 4, !dbg !65
  br label %for.cond, !dbg !67

for.cond:                                         ; preds = %for.inc, %entry
  %5 = load i32, ptr %j, align 4, !dbg !68
  %6 = load i32, ptr %high.addr, align 4, !dbg !70
  %cmp = icmp slt i32 %5, %6, !dbg !71
  br i1 %cmp, label %for.body, label %for.end, !dbg !72

for.body:                                         ; preds = %for.cond
  %7 = load ptr, ptr %a.addr, align 8, !dbg !73
  %8 = load i32, ptr %j, align 4, !dbg !76
  %idxprom1 = sext i32 %8 to i64, !dbg !73
  %arrayidx2 = getelementptr inbounds i32, ptr %7, i64 %idxprom1, !dbg !73
  %9 = load i32, ptr %arrayidx2, align 4, !dbg !73
  %10 = load i32, ptr %pivot, align 4, !dbg !77
  %cmp3 = icmp sle i32 %9, %10, !dbg !78
  br i1 %cmp3, label %if.then, label %if.end, !dbg !78

if.then:                                          ; preds = %for.body
  %11 = load i32, ptr %i, align 4, !dbg !79
  %inc = add nsw i32 %11, 1, !dbg !79
  store i32 %inc, ptr %i, align 4, !dbg !79
    #dbg_declare(ptr %tmp, !81, !DIExpression(), !82)
  %12 = load ptr, ptr %a.addr, align 8, !dbg !83
  %13 = load i32, ptr %i, align 4, !dbg !84
  %idxprom4 = sext i32 %13 to i64, !dbg !83
  %arrayidx5 = getelementptr inbounds i32, ptr %12, i64 %idxprom4, !dbg !83
  %14 = load i32, ptr %arrayidx5, align 4, !dbg !83
  store i32 %14, ptr %tmp, align 4, !dbg !82
  %15 = load ptr, ptr %a.addr, align 8, !dbg !85
  %16 = load i32, ptr %j, align 4, !dbg !86
  %idxprom6 = sext i32 %16 to i64, !dbg !85
  %arrayidx7 = getelementptr inbounds i32, ptr %15, i64 %idxprom6, !dbg !85
  %17 = load i32, ptr %arrayidx7, align 4, !dbg !85
  %18 = load ptr, ptr %a.addr, align 8, !dbg !87
  %19 = load i32, ptr %i, align 4, !dbg !88
  %idxprom8 = sext i32 %19 to i64, !dbg !87
  %arrayidx9 = getelementptr inbounds i32, ptr %18, i64 %idxprom8, !dbg !87
  store i32 %17, ptr %arrayidx9, align 4, !dbg !89
  %20 = load i32, ptr %tmp, align 4, !dbg !90
  %21 = load ptr, ptr %a.addr, align 8, !dbg !91
  %22 = load i32, ptr %j, align 4, !dbg !92
  %idxprom10 = sext i32 %22 to i64, !dbg !91
  %arrayidx11 = getelementptr inbounds i32, ptr %21, i64 %idxprom10, !dbg !91
  store i32 %20, ptr %arrayidx11, align 4, !dbg !93
  br label %if.end, !dbg !94

if.end:                                           ; preds = %if.then, %for.body
  br label %for.inc, !dbg !95

for.inc:                                          ; preds = %if.end
  %23 = load i32, ptr %j, align 4, !dbg !96
  %inc12 = add nsw i32 %23, 1, !dbg !96
  store i32 %inc12, ptr %j, align 4, !dbg !96
  br label %for.cond, !dbg !97, !llvm.loop !98

for.end:                                          ; preds = %for.cond
    #dbg_declare(ptr %tmp13, !101, !DIExpression(), !102)
  %24 = load ptr, ptr %a.addr, align 8, !dbg !103
  %25 = load i32, ptr %i, align 4, !dbg !104
  %add = add nsw i32 %25, 1, !dbg !105
  %idxprom14 = sext i32 %add to i64, !dbg !103
  %arrayidx15 = getelementptr inbounds i32, ptr %24, i64 %idxprom14, !dbg !103
  %26 = load i32, ptr %arrayidx15, align 4, !dbg !103
  store i32 %26, ptr %tmp13, align 4, !dbg !102
  %27 = load ptr, ptr %a.addr, align 8, !dbg !106
  %28 = load i32, ptr %high.addr, align 4, !dbg !107
  %idxprom16 = sext i32 %28 to i64, !dbg !106
  %arrayidx17 = getelementptr inbounds i32, ptr %27, i64 %idxprom16, !dbg !106
  %29 = load i32, ptr %arrayidx17, align 4, !dbg !106
  %30 = load ptr, ptr %a.addr, align 8, !dbg !108
  %31 = load i32, ptr %i, align 4, !dbg !109
  %add18 = add nsw i32 %31, 1, !dbg !110
  %idxprom19 = sext i32 %add18 to i64, !dbg !108
  %arrayidx20 = getelementptr inbounds i32, ptr %30, i64 %idxprom19, !dbg !108
  store i32 %29, ptr %arrayidx20, align 4, !dbg !111
  %32 = load i32, ptr %tmp13, align 4, !dbg !112
  %33 = load ptr, ptr %a.addr, align 8, !dbg !113
  %34 = load i32, ptr %high.addr, align 4, !dbg !114
  %idxprom21 = sext i32 %34 to i64, !dbg !113
  %arrayidx22 = getelementptr inbounds i32, ptr %33, i64 %idxprom21, !dbg !113
  store i32 %32, ptr %arrayidx22, align 4, !dbg !115
  %35 = load i32, ptr %i, align 4, !dbg !116
  %add23 = add nsw i32 %35, 1, !dbg !117
  ret i32 %add23, !dbg !118
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
!18 = !DILocation(line: 24, column: 22, scope: !10)
!19 = !DILocalVariable(name: "low", arg: 2, scope: !10, file: !11, line: 24, type: !15)
!20 = !DILocation(line: 24, column: 29, scope: !10)
!21 = !DILocalVariable(name: "high", arg: 3, scope: !10, file: !11, line: 24, type: !15)
!22 = !DILocation(line: 24, column: 38, scope: !10)
!23 = !DILocation(line: 25, column: 9, scope: !24)
!24 = distinct !DILexicalBlock(scope: !10, file: !11, line: 25, column: 9)
!25 = !DILocation(line: 25, column: 15, scope: !24)
!26 = !DILocation(line: 25, column: 13, scope: !24)
!27 = !DILocalVariable(name: "p", scope: !28, file: !11, line: 26, type: !15)
!28 = distinct !DILexicalBlock(scope: !24, file: !11, line: 25, column: 21)
!29 = !DILocation(line: 26, column: 13, scope: !28)
!30 = !DILocation(line: 26, column: 27, scope: !28)
!31 = !DILocation(line: 26, column: 30, scope: !28)
!32 = !DILocation(line: 26, column: 35, scope: !28)
!33 = !DILocation(line: 26, column: 17, scope: !28)
!34 = !DILocation(line: 28, column: 20, scope: !28)
!35 = !DILocation(line: 28, column: 23, scope: !28)
!36 = !DILocation(line: 28, column: 28, scope: !28)
!37 = !DILocation(line: 28, column: 30, scope: !28)
!38 = !DILocation(line: 28, column: 9, scope: !28)
!39 = !DILocation(line: 29, column: 20, scope: !28)
!40 = !DILocation(line: 29, column: 23, scope: !28)
!41 = !DILocation(line: 29, column: 25, scope: !28)
!42 = !DILocation(line: 29, column: 30, scope: !28)
!43 = !DILocation(line: 29, column: 9, scope: !28)
!44 = !DILocation(line: 30, column: 5, scope: !28)
!45 = !DILocation(line: 31, column: 1, scope: !10)
!46 = distinct !DISubprogram(name: "partition", scope: !11, file: !11, line: 3, type: !47, scopeLine: 3, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !0, retainedNodes: !16)
!47 = !DISubroutineType(types: !48)
!48 = !{!15, !14, !15, !15}
!49 = !DILocalVariable(name: "a", arg: 1, scope: !46, file: !11, line: 3, type: !14)
!50 = !DILocation(line: 3, column: 27, scope: !46)
!51 = !DILocalVariable(name: "low", arg: 2, scope: !46, file: !11, line: 3, type: !15)
!52 = !DILocation(line: 3, column: 34, scope: !46)
!53 = !DILocalVariable(name: "high", arg: 3, scope: !46, file: !11, line: 3, type: !15)
!54 = !DILocation(line: 3, column: 43, scope: !46)
!55 = !DILocalVariable(name: "pivot", scope: !46, file: !11, line: 4, type: !15)
!56 = !DILocation(line: 4, column: 9, scope: !46)
!57 = !DILocation(line: 4, column: 17, scope: !46)
!58 = !DILocation(line: 4, column: 19, scope: !46)
!59 = !DILocalVariable(name: "i", scope: !46, file: !11, line: 5, type: !15)
!60 = !DILocation(line: 5, column: 9, scope: !46)
!61 = !DILocation(line: 5, column: 13, scope: !46)
!62 = !DILocation(line: 5, column: 17, scope: !46)
!63 = !DILocalVariable(name: "j", scope: !64, file: !11, line: 7, type: !15)
!64 = distinct !DILexicalBlock(scope: !46, file: !11, line: 7, column: 5)
!65 = !DILocation(line: 7, column: 14, scope: !64)
!66 = !DILocation(line: 7, column: 18, scope: !64)
!67 = !DILocation(line: 7, column: 10, scope: !64)
!68 = !DILocation(line: 7, column: 23, scope: !69)
!69 = distinct !DILexicalBlock(scope: !64, file: !11, line: 7, column: 5)
!70 = !DILocation(line: 7, column: 27, scope: !69)
!71 = !DILocation(line: 7, column: 25, scope: !69)
!72 = !DILocation(line: 7, column: 5, scope: !64)
!73 = !DILocation(line: 8, column: 13, scope: !74)
!74 = distinct !DILexicalBlock(scope: !75, file: !11, line: 8, column: 13)
!75 = distinct !DILexicalBlock(scope: !69, file: !11, line: 7, column: 38)
!76 = !DILocation(line: 8, column: 15, scope: !74)
!77 = !DILocation(line: 8, column: 21, scope: !74)
!78 = !DILocation(line: 8, column: 18, scope: !74)
!79 = !DILocation(line: 9, column: 13, scope: !80)
!80 = distinct !DILexicalBlock(scope: !74, file: !11, line: 8, column: 28)
!81 = !DILocalVariable(name: "tmp", scope: !80, file: !11, line: 11, type: !15)
!82 = !DILocation(line: 11, column: 17, scope: !80)
!83 = !DILocation(line: 11, column: 23, scope: !80)
!84 = !DILocation(line: 11, column: 25, scope: !80)
!85 = !DILocation(line: 12, column: 20, scope: !80)
!86 = !DILocation(line: 12, column: 22, scope: !80)
!87 = !DILocation(line: 12, column: 13, scope: !80)
!88 = !DILocation(line: 12, column: 15, scope: !80)
!89 = !DILocation(line: 12, column: 18, scope: !80)
!90 = !DILocation(line: 13, column: 20, scope: !80)
!91 = !DILocation(line: 13, column: 13, scope: !80)
!92 = !DILocation(line: 13, column: 15, scope: !80)
!93 = !DILocation(line: 13, column: 18, scope: !80)
!94 = !DILocation(line: 14, column: 9, scope: !80)
!95 = !DILocation(line: 15, column: 5, scope: !75)
!96 = !DILocation(line: 7, column: 33, scope: !69)
!97 = !DILocation(line: 7, column: 5, scope: !69)
!98 = distinct !{!98, !72, !99, !100}
!99 = !DILocation(line: 15, column: 5, scope: !64)
!100 = !{!"llvm.loop.mustprogress"}
!101 = !DILocalVariable(name: "tmp", scope: !46, file: !11, line: 17, type: !15)
!102 = !DILocation(line: 17, column: 9, scope: !46)
!103 = !DILocation(line: 17, column: 15, scope: !46)
!104 = !DILocation(line: 17, column: 17, scope: !46)
!105 = !DILocation(line: 17, column: 19, scope: !46)
!106 = !DILocation(line: 18, column: 16, scope: !46)
!107 = !DILocation(line: 18, column: 18, scope: !46)
!108 = !DILocation(line: 18, column: 5, scope: !46)
!109 = !DILocation(line: 18, column: 7, scope: !46)
!110 = !DILocation(line: 18, column: 9, scope: !46)
!111 = !DILocation(line: 18, column: 14, scope: !46)
!112 = !DILocation(line: 19, column: 15, scope: !46)
!113 = !DILocation(line: 19, column: 5, scope: !46)
!114 = !DILocation(line: 19, column: 7, scope: !46)
!115 = !DILocation(line: 19, column: 13, scope: !46)
!116 = !DILocation(line: 21, column: 12, scope: !46)
!117 = !DILocation(line: 21, column: 14, scope: !46)
!118 = !DILocation(line: 21, column: 5, scope: !46)
