; ModuleID = '/workspace/examples/curated/score.c'
source_filename = "/workspace/examples/curated/score.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @score(i32 noundef %x, i32 noundef %scale) #0 !dbg !10 {
entry:
  %retval = alloca i32, align 4
  %x.addr = alloca i32, align 4
  %scale.addr = alloca i32, align 4
  %limit = alloca i32, align 4
  %wasted = alloca i32, align 4
  %adjusted = alloca i32, align 4
  %weighted = alloca i32, align 4
  store i32 %x, ptr %x.addr, align 4
    #dbg_declare(ptr %x.addr, !16, !DIExpression(), !17)
  store i32 %scale, ptr %scale.addr, align 4
    #dbg_declare(ptr %scale.addr, !18, !DIExpression(), !19)
    #dbg_declare(ptr %limit, !20, !DIExpression(), !21)
  %0 = load i32, ptr %scale.addr, align 4, !dbg !22
  %mul = mul nsw i32 %0, 32, !dbg !23
  store i32 %mul, ptr %limit, align 4, !dbg !21
    #dbg_declare(ptr %wasted, !24, !DIExpression(), !25)
  %1 = load i32, ptr %scale.addr, align 4, !dbg !26
  %2 = load i32, ptr %scale.addr, align 4, !dbg !27
  %mul1 = mul nsw i32 %1, %2, !dbg !28
  %3 = load i32, ptr %scale.addr, align 4, !dbg !29
  %4 = load i32, ptr %scale.addr, align 4, !dbg !30
  %mul2 = mul nsw i32 %3, %4, !dbg !31
  %sub = sub nsw i32 %mul1, %mul2, !dbg !32
  store i32 %sub, ptr %wasted, align 4, !dbg !25
    #dbg_declare(ptr %adjusted, !33, !DIExpression(), !34)
  %5 = load i32, ptr %x.addr, align 4, !dbg !35
  %sub3 = sub nsw i32 %5, 128, !dbg !36
  store i32 %sub3, ptr %adjusted, align 4, !dbg !34
    #dbg_declare(ptr %weighted, !37, !DIExpression(), !38)
  %6 = load i32, ptr %adjusted, align 4, !dbg !39
  %7 = load i32, ptr %scale.addr, align 4, !dbg !40
  %mul4 = mul nsw i32 %6, %7, !dbg !41
  store i32 %mul4, ptr %weighted, align 4, !dbg !38
  %8 = load i32, ptr %weighted, align 4, !dbg !42
  %9 = load i32, ptr %limit, align 4, !dbg !44
  %cmp = icmp sgt i32 %8, %9, !dbg !45
  br i1 %cmp, label %if.then, label %if.end, !dbg !45

if.then:                                          ; preds = %entry
  %10 = load i32, ptr %limit, align 4, !dbg !46
  store i32 %10, ptr %retval, align 4, !dbg !47
  br label %return, !dbg !47

if.end:                                           ; preds = %entry
  %11 = load i32, ptr %weighted, align 4, !dbg !48
  %12 = load i32, ptr %wasted, align 4, !dbg !49
  %add = add nsw i32 %11, %12, !dbg !50
  store i32 %add, ptr %retval, align 4, !dbg !51
  br label %return, !dbg !51

return:                                           ; preds = %if.end, %if.then
  %13 = load i32, ptr %retval, align 4, !dbg !52
  ret i32 %13, !dbg !52
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
!17 = !DILocation(line: 1, column: 15, scope: !10)
!18 = !DILocalVariable(name: "scale", arg: 2, scope: !10, file: !11, line: 1, type: !14)
!19 = !DILocation(line: 1, column: 22, scope: !10)
!20 = !DILocalVariable(name: "limit", scope: !10, file: !11, line: 2, type: !14)
!21 = !DILocation(line: 2, column: 9, scope: !10)
!22 = !DILocation(line: 2, column: 20, scope: !10)
!23 = !DILocation(line: 2, column: 26, scope: !10)
!24 = !DILocalVariable(name: "wasted", scope: !10, file: !11, line: 3, type: !14)
!25 = !DILocation(line: 3, column: 9, scope: !10)
!26 = !DILocation(line: 3, column: 20, scope: !10)
!27 = !DILocation(line: 3, column: 28, scope: !10)
!28 = !DILocation(line: 3, column: 26, scope: !10)
!29 = !DILocation(line: 3, column: 36, scope: !10)
!30 = !DILocation(line: 3, column: 44, scope: !10)
!31 = !DILocation(line: 3, column: 42, scope: !10)
!32 = !DILocation(line: 3, column: 34, scope: !10)
!33 = !DILocalVariable(name: "adjusted", scope: !10, file: !11, line: 4, type: !14)
!34 = !DILocation(line: 4, column: 9, scope: !10)
!35 = !DILocation(line: 4, column: 20, scope: !10)
!36 = !DILocation(line: 4, column: 22, scope: !10)
!37 = !DILocalVariable(name: "weighted", scope: !10, file: !11, line: 5, type: !14)
!38 = !DILocation(line: 5, column: 9, scope: !10)
!39 = !DILocation(line: 5, column: 20, scope: !10)
!40 = !DILocation(line: 5, column: 31, scope: !10)
!41 = !DILocation(line: 5, column: 29, scope: !10)
!42 = !DILocation(line: 7, column: 9, scope: !43)
!43 = distinct !DILexicalBlock(scope: !10, file: !11, line: 7, column: 9)
!44 = !DILocation(line: 7, column: 20, scope: !43)
!45 = !DILocation(line: 7, column: 18, scope: !43)
!46 = !DILocation(line: 8, column: 16, scope: !43)
!47 = !DILocation(line: 8, column: 9, scope: !43)
!48 = !DILocation(line: 10, column: 12, scope: !10)
!49 = !DILocation(line: 10, column: 23, scope: !10)
!50 = !DILocation(line: 10, column: 21, scope: !10)
!51 = !DILocation(line: 10, column: 5, scope: !10)
!52 = !DILocation(line: 11, column: 1, scope: !10)
