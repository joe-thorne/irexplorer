; ModuleID = '/workspace/out/asm_goto_10_loop_cleanup.ll'
source_filename = "/workspace/user-programs/asm_goto.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @is_positive(i32 noundef %x) #0 !dbg !10 {
entry:
    #dbg_value(i32 %x, !16, !DIExpression(), !17)
  callbr void asm sideeffect "testl $0, $0\0A\09jg ${1:l}", "r,!i,~{cc},~{dirflag},~{fpsr},~{flags}"(i32 %x) #1
          to label %return [label %positive], !dbg !18, !srcloc !19

positive:                                         ; preds = %entry
    #dbg_label(!20, !21)
  br label %return, !dbg !22

return:                                           ; preds = %positive, %entry
  %retval.0 = phi i32 [ 1, %positive ], [ 0, %entry ], !dbg !17
  ret i32 %retval.0, !dbg !23
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @main() #0 !dbg !24 {
entry:
  %call = call i32 @is_positive(i32 noundef 5), !dbg !27
  %tobool.not = icmp eq i32 %call, 0, !dbg !27
  br i1 %tobool.not, label %land.end, label %land.rhs, !dbg !28

land.rhs:                                         ; preds = %entry
  %call1 = call i32 @is_positive(i32 noundef -5), !dbg !29
  %tobool2.not = icmp ne i32 %call1, 0, !dbg !30
  %0 = zext i1 %tobool2.not to i32, !dbg !27
  br label %land.end

land.end:                                         ; preds = %land.rhs, %entry
  %not. = phi i32 [ 1, %entry ], [ %0, %land.rhs ], !dbg !31
  ret i32 %not., !dbg !32
}

attributes #0 = { noinline nounwind uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind }

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!2, !3, !4, !5, !6, !7, !8}
!llvm.ident = !{!9}

!0 = distinct !DICompileUnit(language: DW_LANG_C11, file: !1, producer: "clang version 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, splitDebugInlining: false, nameTableKind: None)
!1 = !DIFile(filename: "/workspace/user-programs/asm_goto.c", directory: "/workspace", checksumkind: CSK_MD5, checksum: "9b7683a669d768aeafd26d8337345695")
!2 = !{i32 7, !"Dwarf Version", i32 5}
!3 = !{i32 2, !"Debug Info Version", i32 3}
!4 = !{i32 1, !"wchar_size", i32 4}
!5 = !{i32 8, !"PIC Level", i32 2}
!6 = !{i32 7, !"PIE Level", i32 2}
!7 = !{i32 7, !"uwtable", i32 2}
!8 = !{i32 7, !"frame-pointer", i32 2}
!9 = !{!"clang version 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)"}
!10 = distinct !DISubprogram(name: "is_positive", scope: !11, file: !11, line: 1, type: !12, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !15)
!11 = !DIFile(filename: "user-programs/asm_goto.c", directory: "/workspace", checksumkind: CSK_MD5, checksum: "9b7683a669d768aeafd26d8337345695")
!12 = !DISubroutineType(types: !13)
!13 = !{!14, !14}
!14 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!15 = !{}
!16 = !DILocalVariable(name: "x", arg: 1, scope: !10, file: !11, line: 1, type: !14)
!17 = !DILocation(line: 0, scope: !10)
!18 = !DILocation(line: 2, column: 5, scope: !10)
!19 = !{i64 40, i64 55}
!20 = !DILabel(scope: !10, name: "positive", file: !11, line: 4, column: 1)
!21 = !DILocation(line: 4, column: 1, scope: !10)
!22 = !DILocation(line: 5, column: 5, scope: !10)
!23 = !DILocation(line: 6, column: 1, scope: !10)
!24 = distinct !DISubprogram(name: "main", scope: !11, file: !11, line: 8, type: !25, scopeLine: 8, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !0)
!25 = !DISubroutineType(types: !26)
!26 = !{!14}
!27 = !DILocation(line: 9, column: 12, scope: !24)
!28 = !DILocation(line: 9, column: 27, scope: !24)
!29 = !DILocation(line: 9, column: 31, scope: !24)
!30 = !DILocation(line: 9, column: 30, scope: !24)
!31 = !DILocation(line: 0, scope: !24)
!32 = !DILocation(line: 9, column: 5, scope: !24)
