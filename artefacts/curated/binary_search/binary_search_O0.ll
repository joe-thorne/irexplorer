; ModuleID = '/workspace/examples/curated/binary_search.c'
source_filename = "/workspace/examples/curated/binary_search.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @binary_search(ptr noundef %a, i32 noundef %n, i32 noundef %key) #0 !dbg !12 {
entry:
  %retval = alloca i32, align 4
  %a.addr = alloca ptr, align 8
  %n.addr = alloca i32, align 4
  %key.addr = alloca i32, align 4
  %lo = alloca i32, align 4
  %hi = alloca i32, align 4
  %mid = alloca i32, align 4
  store ptr %a, ptr %a.addr, align 8
    #dbg_declare(ptr %a.addr, !19, !DIExpression(), !20)
  store i32 %n, ptr %n.addr, align 4
    #dbg_declare(ptr %n.addr, !21, !DIExpression(), !22)
  store i32 %key, ptr %key.addr, align 4
    #dbg_declare(ptr %key.addr, !23, !DIExpression(), !24)
    #dbg_declare(ptr %lo, !25, !DIExpression(), !26)
  store i32 0, ptr %lo, align 4, !dbg !26
    #dbg_declare(ptr %hi, !27, !DIExpression(), !28)
  %0 = load i32, ptr %n.addr, align 4, !dbg !29
  store i32 %0, ptr %hi, align 4, !dbg !28
  br label %while.cond, !dbg !30

while.cond:                                       ; preds = %if.end, %entry
  %1 = load i32, ptr %lo, align 4, !dbg !31
  %2 = load i32, ptr %hi, align 4, !dbg !32
  %cmp = icmp slt i32 %1, %2, !dbg !33
  br i1 %cmp, label %while.body, label %while.end, !dbg !30

while.body:                                       ; preds = %while.cond
    #dbg_declare(ptr %mid, !34, !DIExpression(), !36)
  %3 = load i32, ptr %lo, align 4, !dbg !37
  %4 = load i32, ptr %hi, align 4, !dbg !38
  %5 = load i32, ptr %lo, align 4, !dbg !39
  %sub = sub nsw i32 %4, %5, !dbg !40
  %div = sdiv i32 %sub, 2, !dbg !41
  %add = add nsw i32 %3, %div, !dbg !42
  store i32 %add, ptr %mid, align 4, !dbg !36
  %6 = load ptr, ptr %a.addr, align 8, !dbg !43
  %7 = load i32, ptr %mid, align 4, !dbg !45
  %idxprom = sext i32 %7 to i64, !dbg !43
  %arrayidx = getelementptr inbounds i32, ptr %6, i64 %idxprom, !dbg !43
  %8 = load i32, ptr %arrayidx, align 4, !dbg !43
  %9 = load i32, ptr %key.addr, align 4, !dbg !46
  %cmp1 = icmp slt i32 %8, %9, !dbg !47
  br i1 %cmp1, label %if.then, label %if.else, !dbg !47

if.then:                                          ; preds = %while.body
  %10 = load i32, ptr %mid, align 4, !dbg !48
  %add2 = add nsw i32 %10, 1, !dbg !50
  store i32 %add2, ptr %lo, align 4, !dbg !51
  br label %if.end, !dbg !52

if.else:                                          ; preds = %while.body
  %11 = load i32, ptr %mid, align 4, !dbg !53
  store i32 %11, ptr %hi, align 4, !dbg !55
  br label %if.end

if.end:                                           ; preds = %if.else, %if.then
  br label %while.cond, !dbg !30, !llvm.loop !56

while.end:                                        ; preds = %while.cond
  %12 = load i32, ptr %lo, align 4, !dbg !59
  %13 = load i32, ptr %n.addr, align 4, !dbg !61
  %cmp3 = icmp slt i32 %12, %13, !dbg !62
  br i1 %cmp3, label %land.lhs.true, label %if.end8, !dbg !63

land.lhs.true:                                    ; preds = %while.end
  %14 = load ptr, ptr %a.addr, align 8, !dbg !64
  %15 = load i32, ptr %lo, align 4, !dbg !65
  %idxprom4 = sext i32 %15 to i64, !dbg !64
  %arrayidx5 = getelementptr inbounds i32, ptr %14, i64 %idxprom4, !dbg !64
  %16 = load i32, ptr %arrayidx5, align 4, !dbg !64
  %17 = load i32, ptr %key.addr, align 4, !dbg !66
  %cmp6 = icmp eq i32 %16, %17, !dbg !67
  br i1 %cmp6, label %if.then7, label %if.end8, !dbg !63

if.then7:                                         ; preds = %land.lhs.true
  %18 = load i32, ptr %lo, align 4, !dbg !68
  store i32 %18, ptr %retval, align 4, !dbg !70
  br label %return, !dbg !70

if.end8:                                          ; preds = %land.lhs.true, %while.end
  store i32 -1, ptr %retval, align 4, !dbg !71
  br label %return, !dbg !71

return:                                           ; preds = %if.end8, %if.then7
  %19 = load i32, ptr %retval, align 4, !dbg !72
  ret i32 %19, !dbg !72
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
!20 = !DILocation(line: 1, column: 30, scope: !12)
!21 = !DILocalVariable(name: "n", arg: 2, scope: !12, file: !13, line: 1, type: !3)
!22 = !DILocation(line: 1, column: 37, scope: !12)
!23 = !DILocalVariable(name: "key", arg: 3, scope: !12, file: !13, line: 1, type: !3)
!24 = !DILocation(line: 1, column: 44, scope: !12)
!25 = !DILocalVariable(name: "lo", scope: !12, file: !13, line: 2, type: !3)
!26 = !DILocation(line: 2, column: 9, scope: !12)
!27 = !DILocalVariable(name: "hi", scope: !12, file: !13, line: 3, type: !3)
!28 = !DILocation(line: 3, column: 9, scope: !12)
!29 = !DILocation(line: 3, column: 14, scope: !12)
!30 = !DILocation(line: 5, column: 5, scope: !12)
!31 = !DILocation(line: 5, column: 12, scope: !12)
!32 = !DILocation(line: 5, column: 17, scope: !12)
!33 = !DILocation(line: 5, column: 15, scope: !12)
!34 = !DILocalVariable(name: "mid", scope: !35, file: !13, line: 6, type: !3)
!35 = distinct !DILexicalBlock(scope: !12, file: !13, line: 5, column: 21)
!36 = !DILocation(line: 6, column: 13, scope: !35)
!37 = !DILocation(line: 6, column: 19, scope: !35)
!38 = !DILocation(line: 6, column: 25, scope: !35)
!39 = !DILocation(line: 6, column: 30, scope: !35)
!40 = !DILocation(line: 6, column: 28, scope: !35)
!41 = !DILocation(line: 6, column: 34, scope: !35)
!42 = !DILocation(line: 6, column: 22, scope: !35)
!43 = !DILocation(line: 8, column: 13, scope: !44)
!44 = distinct !DILexicalBlock(scope: !35, file: !13, line: 8, column: 13)
!45 = !DILocation(line: 8, column: 15, scope: !44)
!46 = !DILocation(line: 8, column: 22, scope: !44)
!47 = !DILocation(line: 8, column: 20, scope: !44)
!48 = !DILocation(line: 9, column: 18, scope: !49)
!49 = distinct !DILexicalBlock(scope: !44, file: !13, line: 8, column: 27)
!50 = !DILocation(line: 9, column: 22, scope: !49)
!51 = !DILocation(line: 9, column: 16, scope: !49)
!52 = !DILocation(line: 10, column: 9, scope: !49)
!53 = !DILocation(line: 11, column: 18, scope: !54)
!54 = distinct !DILexicalBlock(scope: !44, file: !13, line: 10, column: 16)
!55 = !DILocation(line: 11, column: 16, scope: !54)
!56 = distinct !{!56, !30, !57, !58}
!57 = !DILocation(line: 13, column: 5, scope: !12)
!58 = !{!"llvm.loop.mustprogress"}
!59 = !DILocation(line: 15, column: 9, scope: !60)
!60 = distinct !DILexicalBlock(scope: !12, file: !13, line: 15, column: 9)
!61 = !DILocation(line: 15, column: 14, scope: !60)
!62 = !DILocation(line: 15, column: 12, scope: !60)
!63 = !DILocation(line: 15, column: 16, scope: !60)
!64 = !DILocation(line: 15, column: 19, scope: !60)
!65 = !DILocation(line: 15, column: 21, scope: !60)
!66 = !DILocation(line: 15, column: 28, scope: !60)
!67 = !DILocation(line: 15, column: 25, scope: !60)
!68 = !DILocation(line: 16, column: 21, scope: !69)
!69 = distinct !DILexicalBlock(scope: !60, file: !13, line: 15, column: 33)
!70 = !DILocation(line: 16, column: 9, scope: !69)
!71 = !DILocation(line: 19, column: 5, scope: !12)
!72 = !DILocation(line: 20, column: 1, scope: !12)
