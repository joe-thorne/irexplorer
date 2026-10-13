; ModuleID = '/workspace/out/ends_in_abort_08_licm.ll'
source_filename = "/workspace/user-programs/ends_in_abort.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @checked_divide(i32 noundef %numerator, i32 noundef %denominator) #0 !dbg !10 {
entry:
    #dbg_value(i32 %numerator, !16, !DIExpression(), !17)
    #dbg_value(i32 %denominator, !18, !DIExpression(), !17)
  %cmp = icmp eq i32 %denominator, 0, !dbg !19
  br i1 %cmp, label %if.then, label %if.end, !dbg !19

if.then:                                          ; preds = %entry
  call void @abort() #2, !dbg !21
  unreachable, !dbg !21

if.end:                                           ; preds = %entry
  %div = sdiv i32 %numerator, %denominator, !dbg !23
  ret i32 %div, !dbg !24
}

; Function Attrs: noreturn nounwind
declare void @abort() #1

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @main() #0 !dbg !25 {
entry:
  %call = call i32 @checked_divide(i32 noundef 84, i32 noundef 2), !dbg !28
  %cmp = icmp ne i32 %call, 42, !dbg !29
  %cond = zext i1 %cmp to i32, !dbg !28
  ret i32 %cond, !dbg !30
}

attributes #0 = { noinline nounwind uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { noreturn nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { noreturn nounwind }

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!2, !3, !4, !5, !6, !7, !8}
!llvm.ident = !{!9}

!0 = distinct !DICompileUnit(language: DW_LANG_C11, file: !1, producer: "clang version 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, splitDebugInlining: false, nameTableKind: None)
!1 = !DIFile(filename: "/workspace/user-programs/ends_in_abort.c", directory: "/workspace", checksumkind: CSK_MD5, checksum: "a0d9c3f07f9a0f730d45b6b3ef3cf908")
!2 = !{i32 7, !"Dwarf Version", i32 5}
!3 = !{i32 2, !"Debug Info Version", i32 3}
!4 = !{i32 1, !"wchar_size", i32 4}
!5 = !{i32 8, !"PIC Level", i32 2}
!6 = !{i32 7, !"PIE Level", i32 2}
!7 = !{i32 7, !"uwtable", i32 2}
!8 = !{i32 7, !"frame-pointer", i32 2}
!9 = !{!"clang version 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)"}
!10 = distinct !DISubprogram(name: "checked_divide", scope: !11, file: !11, line: 3, type: !12, scopeLine: 3, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !15)
!11 = !DIFile(filename: "user-programs/ends_in_abort.c", directory: "/workspace", checksumkind: CSK_MD5, checksum: "a0d9c3f07f9a0f730d45b6b3ef3cf908")
!12 = !DISubroutineType(types: !13)
!13 = !{!14, !14, !14}
!14 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!15 = !{}
!16 = !DILocalVariable(name: "numerator", arg: 1, scope: !10, file: !11, line: 3, type: !14)
!17 = !DILocation(line: 0, scope: !10)
!18 = !DILocalVariable(name: "denominator", arg: 2, scope: !10, file: !11, line: 3, type: !14)
!19 = !DILocation(line: 4, column: 21, scope: !20)
!20 = distinct !DILexicalBlock(scope: !10, file: !11, line: 4, column: 9)
!21 = !DILocation(line: 5, column: 9, scope: !22)
!22 = distinct !DILexicalBlock(scope: !20, file: !11, line: 4, column: 27)
!23 = !DILocation(line: 7, column: 22, scope: !10)
!24 = !DILocation(line: 7, column: 5, scope: !10)
!25 = distinct !DISubprogram(name: "main", scope: !11, file: !11, line: 10, type: !26, scopeLine: 10, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !0)
!26 = !DISubroutineType(types: !27)
!27 = !{!14}
!28 = !DILocation(line: 11, column: 12, scope: !25)
!29 = !DILocation(line: 11, column: 34, scope: !25)
!30 = !DILocation(line: 11, column: 5, scope: !25)
