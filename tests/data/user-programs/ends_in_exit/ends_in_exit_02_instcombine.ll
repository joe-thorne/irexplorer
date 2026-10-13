; ModuleID = '/workspace/out/ends_in_exit_01_mem2reg.ll'
source_filename = "/workspace/user-programs/ends_in_exit.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@.str = private unnamed_addr constant [12 x i8] c"not a digit\00", align 1, !dbg !0
@.str.1 = private unnamed_addr constant [5 x i8] c"2024\00", align 1, !dbg !7
@stderr = external global ptr, align 8
@.str.2 = private unnamed_addr constant [11 x i8] c"error: %s\0A\00", align 1, !dbg !12

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @parse_digit(i8 noundef signext %c) #0 !dbg !28 {
entry:
    #dbg_value(i8 %c, !33, !DIExpression(), !34)
  %cmp = icmp slt i8 %c, 48, !dbg !35
  br i1 %cmp, label %if.then, label %lor.lhs.false, !dbg !37

lor.lhs.false:                                    ; preds = %entry
  %cmp3 = icmp ugt i8 %c, 57, !dbg !38
  br i1 %cmp3, label %if.then, label %if.end, !dbg !37

if.then:                                          ; preds = %lor.lhs.false, %entry
  call void @fail(ptr noundef nonnull @.str), !dbg !39
  br label %if.end, !dbg !41

if.end:                                           ; preds = %if.then, %lor.lhs.false
  %conv5 = sext i8 %c to i32, !dbg !42
  %sub = add nsw i32 %conv5, -48, !dbg !43
  ret i32 %sub, !dbg !44
}

; Function Attrs: noinline nounwind uwtable
define internal void @fail(ptr noundef %message) #0 !dbg !45 {
entry:
    #dbg_value(ptr %message, !50, !DIExpression(), !51)
  %0 = load ptr, ptr @stderr, align 8, !dbg !52
  %call = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %0, ptr noundef nonnull @.str.2, ptr noundef %message) #3, !dbg !53
  call void @exit(i32 noundef 1) #4, !dbg !54
  unreachable, !dbg !54
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @main() #0 !dbg !55 {
entry:
    #dbg_value(i32 0, !58, !DIExpression(), !59)
    #dbg_value(ptr @.str.1, !60, !DIExpression(), !62)
  br label %for.cond, !dbg !63

for.cond:                                         ; preds = %for.inc, %entry
  %total.0 = phi i32 [ 0, %entry ], [ %add, %for.inc ], !dbg !59
  %p.0 = phi ptr [ @.str.1, %entry ], [ %incdec.ptr, %for.inc ], !dbg !64
    #dbg_value(ptr %p.0, !60, !DIExpression(), !62)
    #dbg_value(i32 %total.0, !58, !DIExpression(), !59)
  %0 = load i8, ptr %p.0, align 1, !dbg !65
  %cmp.not = icmp eq i8 %0, 0, !dbg !67
  br i1 %cmp.not, label %for.end, label %for.body, !dbg !68

for.body:                                         ; preds = %for.cond
  %1 = load i8, ptr %p.0, align 1, !dbg !69
  %call = call i32 @parse_digit(i8 noundef signext %1), !dbg !71
    #dbg_value(!DIArgList(i32 %total.0, i32 %call), !58, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_constu, 10, DW_OP_mul, DW_OP_LLVM_arg, 1, DW_OP_plus, DW_OP_stack_value), !59)
  br label %for.inc, !dbg !72

for.inc:                                          ; preds = %for.body
  %mul = mul nsw i32 %total.0, 10, !dbg !73
    #dbg_value(!DIArgList(i32 %mul, i32 %call), !58, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_plus, DW_OP_stack_value), !59)
  %add = add nsw i32 %mul, %call, !dbg !74
    #dbg_value(i32 %add, !58, !DIExpression(), !59)
  %incdec.ptr = getelementptr inbounds nuw i8, ptr %p.0, i64 1, !dbg !75
    #dbg_value(ptr %incdec.ptr, !60, !DIExpression(), !62)
  br label %for.cond, !dbg !76, !llvm.loop !77

for.end:                                          ; preds = %for.cond
  %cmp2 = icmp ne i32 %total.0, 2024, !dbg !80
  %cond = zext i1 %cmp2 to i32, !dbg !81
  ret i32 %cond, !dbg !82
}

; Function Attrs: nounwind
declare i32 @fprintf(ptr noundef, ptr noundef, ...) #1

; Function Attrs: noreturn nounwind
declare void @exit(i32 noundef) #2

attributes #0 = { noinline nounwind uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { noreturn nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { cold nounwind }
attributes #4 = { cold noreturn nounwind }

!llvm.dbg.cu = !{!17}
!llvm.module.flags = !{!20, !21, !22, !23, !24, !25, !26}
!llvm.ident = !{!27}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(scope: null, file: !2, line: 11, type: !3, isLocal: true, isDefinition: true)
!2 = !DIFile(filename: "user-programs/ends_in_exit.c", directory: "/workspace", checksumkind: CSK_MD5, checksum: "e5230e764d01bf37a1ff141909c00bde")
!3 = !DICompositeType(tag: DW_TAG_array_type, baseType: !4, size: 96, elements: !5)
!4 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!5 = !{!6}
!6 = !DISubrange(count: 12)
!7 = !DIGlobalVariableExpression(var: !8, expr: !DIExpression())
!8 = distinct !DIGlobalVariable(scope: null, file: !2, line: 18, type: !9, isLocal: true, isDefinition: true)
!9 = !DICompositeType(tag: DW_TAG_array_type, baseType: !4, size: 40, elements: !10)
!10 = !{!11}
!11 = !DISubrange(count: 5)
!12 = !DIGlobalVariableExpression(var: !13, expr: !DIExpression())
!13 = distinct !DIGlobalVariable(scope: null, file: !2, line: 5, type: !14, isLocal: true, isDefinition: true)
!14 = !DICompositeType(tag: DW_TAG_array_type, baseType: !4, size: 88, elements: !15)
!15 = !{!16}
!16 = !DISubrange(count: 11)
!17 = distinct !DICompileUnit(language: DW_LANG_C11, file: !18, producer: "clang version 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, globals: !19, splitDebugInlining: false, nameTableKind: None)
!18 = !DIFile(filename: "/workspace/user-programs/ends_in_exit.c", directory: "/workspace", checksumkind: CSK_MD5, checksum: "e5230e764d01bf37a1ff141909c00bde")
!19 = !{!0, !7, !12}
!20 = !{i32 7, !"Dwarf Version", i32 5}
!21 = !{i32 2, !"Debug Info Version", i32 3}
!22 = !{i32 1, !"wchar_size", i32 4}
!23 = !{i32 8, !"PIC Level", i32 2}
!24 = !{i32 7, !"PIE Level", i32 2}
!25 = !{i32 7, !"uwtable", i32 2}
!26 = !{i32 7, !"frame-pointer", i32 2}
!27 = !{!"clang version 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)"}
!28 = distinct !DISubprogram(name: "parse_digit", scope: !2, file: !2, line: 9, type: !29, scopeLine: 9, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !17, retainedNodes: !32)
!29 = !DISubroutineType(types: !30)
!30 = !{!31, !4}
!31 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!32 = !{}
!33 = !DILocalVariable(name: "c", arg: 1, scope: !28, file: !2, line: 9, type: !4)
!34 = !DILocation(line: 0, scope: !28)
!35 = !DILocation(line: 10, column: 11, scope: !36)
!36 = distinct !DILexicalBlock(scope: !28, file: !2, line: 10, column: 9)
!37 = !DILocation(line: 10, column: 17, scope: !36)
!38 = !DILocation(line: 10, column: 22, scope: !36)
!39 = !DILocation(line: 11, column: 9, scope: !40)
!40 = distinct !DILexicalBlock(scope: !36, file: !2, line: 10, column: 29)
!41 = !DILocation(line: 12, column: 5, scope: !40)
!42 = !DILocation(line: 13, column: 12, scope: !28)
!43 = !DILocation(line: 13, column: 14, scope: !28)
!44 = !DILocation(line: 13, column: 5, scope: !28)
!45 = distinct !DISubprogram(name: "fail", scope: !2, file: !2, line: 4, type: !46, scopeLine: 4, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !17, retainedNodes: !32)
!46 = !DISubroutineType(types: !47)
!47 = !{null, !48}
!48 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !49, size: 64)
!49 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !4)
!50 = !DILocalVariable(name: "message", arg: 1, scope: !45, file: !2, line: 4, type: !48)
!51 = !DILocation(line: 0, scope: !45)
!52 = !DILocation(line: 5, column: 13, scope: !45)
!53 = !DILocation(line: 5, column: 5, scope: !45)
!54 = !DILocation(line: 6, column: 5, scope: !45)
!55 = distinct !DISubprogram(name: "main", scope: !2, file: !2, line: 16, type: !56, scopeLine: 16, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !17, retainedNodes: !32)
!56 = !DISubroutineType(types: !57)
!57 = !{!31}
!58 = !DILocalVariable(name: "total", scope: !55, file: !2, line: 17, type: !31)
!59 = !DILocation(line: 0, scope: !55)
!60 = !DILocalVariable(name: "p", scope: !61, file: !2, line: 18, type: !48)
!61 = distinct !DILexicalBlock(scope: !55, file: !2, line: 18, column: 5)
!62 = !DILocation(line: 0, scope: !61)
!63 = !DILocation(line: 18, column: 10, scope: !61)
!64 = !DILocation(line: 18, scope: !61)
!65 = !DILocation(line: 18, column: 34, scope: !66)
!66 = distinct !DILexicalBlock(scope: !61, file: !2, line: 18, column: 5)
!67 = !DILocation(line: 18, column: 37, scope: !66)
!68 = !DILocation(line: 18, column: 5, scope: !61)
!69 = !DILocation(line: 19, column: 42, scope: !70)
!70 = distinct !DILexicalBlock(scope: !66, file: !2, line: 18, column: 51)
!71 = !DILocation(line: 19, column: 30, scope: !70)
!72 = !DILocation(line: 20, column: 5, scope: !70)
!73 = !DILocation(line: 19, column: 23, scope: !70)
!74 = !DILocation(line: 19, column: 28, scope: !70)
!75 = !DILocation(line: 18, column: 47, scope: !66)
!76 = !DILocation(line: 18, column: 5, scope: !66)
!77 = distinct !{!77, !68, !78, !79}
!78 = !DILocation(line: 20, column: 5, scope: !61)
!79 = !{!"llvm.loop.mustprogress"}
!80 = !DILocation(line: 21, column: 18, scope: !55)
!81 = !DILocation(line: 21, column: 12, scope: !55)
!82 = !DILocation(line: 21, column: 5, scope: !55)
