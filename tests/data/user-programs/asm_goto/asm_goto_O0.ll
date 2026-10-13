; ModuleID = '/workspace/user-programs/asm_goto.c'
source_filename = "/workspace/user-programs/asm_goto.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @is_positive(i32 noundef %x) #0 !dbg !10 {
entry:
  %retval = alloca i32, align 4
  %x.addr = alloca i32, align 4
  store i32 %x, ptr %x.addr, align 4
    #dbg_declare(ptr %x.addr, !16, !DIExpression(), !17)
  %0 = load i32, ptr %x.addr, align 4, !dbg !18
  callbr void asm sideeffect "testl $0, $0\0A\09jg ${1:l}", "r,!i,~{cc},~{dirflag},~{fpsr},~{flags}"(i32 %0) #1
          to label %asm.fallthrough [label %positive], !dbg !19, !srcloc !20

asm.fallthrough:                                  ; preds = %entry
  store i32 0, ptr %retval, align 4, !dbg !21
  br label %return, !dbg !21

positive:                                         ; preds = %entry
    #dbg_label(!22, !23)
  store i32 1, ptr %retval, align 4, !dbg !24
  br label %return, !dbg !24

return:                                           ; preds = %positive, %asm.fallthrough
  %1 = load i32, ptr %retval, align 4, !dbg !25
  ret i32 %1, !dbg !25
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @main() #0 !dbg !26 {
entry:
  %retval = alloca i32, align 4
  store i32 0, ptr %retval, align 4
  %call = call i32 @is_positive(i32 noundef 5), !dbg !29
  %tobool = icmp ne i32 %call, 0, !dbg !29
  br i1 %tobool, label %land.rhs, label %land.end, !dbg !30

land.rhs:                                         ; preds = %entry
  %call1 = call i32 @is_positive(i32 noundef -5), !dbg !31
  %tobool2 = icmp ne i32 %call1, 0, !dbg !32
  %lnot = xor i1 %tobool2, true, !dbg !32
  br label %land.end

land.end:                                         ; preds = %land.rhs, %entry
  %0 = phi i1 [ false, %entry ], [ %lnot, %land.rhs ], !dbg !33
  %1 = zext i1 %0 to i64, !dbg !29
  %cond = select i1 %0, i32 0, i32 1, !dbg !29
  ret i32 %cond, !dbg !34
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
!17 = !DILocation(line: 1, column: 21, scope: !10)
!18 = !DILocation(line: 2, column: 56, scope: !10)
!19 = !DILocation(line: 2, column: 5, scope: !10)
!20 = !{i64 40, i64 55}
!21 = !DILocation(line: 3, column: 5, scope: !10)
!22 = !DILabel(scope: !10, name: "positive", file: !11, line: 4, column: 1)
!23 = !DILocation(line: 4, column: 1, scope: !10)
!24 = !DILocation(line: 5, column: 5, scope: !10)
!25 = !DILocation(line: 6, column: 1, scope: !10)
!26 = distinct !DISubprogram(name: "main", scope: !11, file: !11, line: 8, type: !27, scopeLine: 8, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !0)
!27 = !DISubroutineType(types: !28)
!28 = !{!14}
!29 = !DILocation(line: 9, column: 12, scope: !26)
!30 = !DILocation(line: 9, column: 27, scope: !26)
!31 = !DILocation(line: 9, column: 31, scope: !26)
!32 = !DILocation(line: 9, column: 30, scope: !26)
!33 = !DILocation(line: 0, scope: !26)
!34 = !DILocation(line: 9, column: 5, scope: !26)
