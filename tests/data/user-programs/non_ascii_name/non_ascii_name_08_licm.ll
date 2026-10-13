; ModuleID = '/workspace/out/non_ascii_name_07_loop_rotate.ll'
source_filename = "/workspace/user-programs/non_ascii_name.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @"caf\C3\A9_total"(i32 noundef %cups, i32 noundef %price) #0 !dbg !10 {
entry:
    #dbg_value(i32 %cups, !16, !DIExpression(), !17)
    #dbg_value(i32 %price, !18, !DIExpression(), !17)
  %mul = mul nsw i32 %cups, %price, !dbg !19
  ret i32 %mul, !dbg !20
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @main() #0 !dbg !21 {
entry:
  %call = call i32 @"caf\C3\A9_total"(i32 noundef 3, i32 noundef 4), !dbg !24
  %cmp = icmp ne i32 %call, 12, !dbg !25
  %cond = zext i1 %cmp to i32, !dbg !24
  ret i32 %cond, !dbg !26
}

attributes #0 = { noinline nounwind uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!2, !3, !4, !5, !6, !7, !8}
!llvm.ident = !{!9}

!0 = distinct !DICompileUnit(language: DW_LANG_C11, file: !1, producer: "clang version 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, splitDebugInlining: false, nameTableKind: None)
!1 = !DIFile(filename: "/workspace/user-programs/non_ascii_name.c", directory: "/workspace", checksumkind: CSK_MD5, checksum: "110a8b231563f0173026ce1c6538904b")
!2 = !{i32 7, !"Dwarf Version", i32 5}
!3 = !{i32 2, !"Debug Info Version", i32 3}
!4 = !{i32 1, !"wchar_size", i32 4}
!5 = !{i32 8, !"PIC Level", i32 2}
!6 = !{i32 7, !"PIE Level", i32 2}
!7 = !{i32 7, !"uwtable", i32 2}
!8 = !{i32 7, !"frame-pointer", i32 2}
!9 = !{!"clang version 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)"}
!10 = distinct !DISubprogram(name: "caf\C3\A9_total", scope: !11, file: !11, line: 2, type: !12, scopeLine: 2, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !15)
!11 = !DIFile(filename: "user-programs/non_ascii_name.c", directory: "/workspace", checksumkind: CSK_MD5, checksum: "110a8b231563f0173026ce1c6538904b")
!12 = !DISubroutineType(types: !13)
!13 = !{!14, !14, !14}
!14 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!15 = !{}
!16 = !DILocalVariable(name: "cups", arg: 1, scope: !10, file: !11, line: 2, type: !14)
!17 = !DILocation(line: 0, scope: !10)
!18 = !DILocalVariable(name: "price", arg: 2, scope: !10, file: !11, line: 2, type: !14)
!19 = !DILocation(line: 3, column: 17, scope: !10)
!20 = !DILocation(line: 3, column: 5, scope: !10)
!21 = distinct !DISubprogram(name: "main", scope: !11, file: !11, line: 6, type: !22, scopeLine: 6, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !0)
!22 = !DISubroutineType(types: !23)
!23 = !{!14}
!24 = !DILocation(line: 7, column: 12, scope: !21)
!25 = !DILocation(line: 7, column: 30, scope: !21)
!26 = !DILocation(line: 7, column: 5, scope: !21)
