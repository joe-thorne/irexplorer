; ModuleID = '/workspace/out/ends_in_exit_07_loop_rotate.ll'
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
  %0 = add i8 %c, -58, !dbg !35
  %or.cond = icmp ult i8 %0, -10, !dbg !35
  br i1 %or.cond, label %if.then, label %if.end, !dbg !35

if.then:                                          ; preds = %entry
  call void @fail(ptr noundef nonnull @.str), !dbg !37
  br label %if.end, !dbg !39

if.end:                                           ; preds = %if.then, %entry
  %conv5 = sext i8 %c to i32, !dbg !40
  %sub = add nsw i32 %conv5, -48, !dbg !41
  ret i32 %sub, !dbg !42
}

; Function Attrs: noinline nounwind uwtable
define internal void @fail(ptr noundef %message) #0 !dbg !43 {
entry:
    #dbg_value(ptr %message, !48, !DIExpression(), !49)
  %0 = load ptr, ptr @stderr, align 8, !dbg !50
  %call = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %0, ptr noundef nonnull @.str.2, ptr noundef %message) #3, !dbg !51
  call void @exit(i32 noundef 1) #4, !dbg !52
  unreachable, !dbg !52
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @main() #0 !dbg !53 {
entry:
    #dbg_value(i32 0, !56, !DIExpression(), !57)
    #dbg_value(ptr @.str.1, !58, !DIExpression(), !60)
  br label %for.body, !dbg !61

for.body:                                         ; preds = %for.body, %entry
  %0 = phi i8 [ 50, %entry ], [ %1, %for.body ]
  %p.02 = phi ptr [ @.str.1, %entry ], [ %incdec.ptr, %for.body ]
  %total.01 = phi i32 [ 0, %entry ], [ %add, %for.body ]
    #dbg_value(ptr %p.02, !58, !DIExpression(), !60)
    #dbg_value(i32 %total.01, !56, !DIExpression(), !57)
  %call = call i32 @parse_digit(i8 noundef signext %0), !dbg !62
    #dbg_value(!DIArgList(i32 %total.01, i32 %call), !56, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_constu, 10, DW_OP_mul, DW_OP_LLVM_arg, 1, DW_OP_plus, DW_OP_stack_value), !57)
  %mul = mul nsw i32 %total.01, 10, !dbg !65
    #dbg_value(!DIArgList(i32 %mul, i32 %call), !56, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_plus, DW_OP_stack_value), !57)
  %add = add nsw i32 %mul, %call, !dbg !66
    #dbg_value(i32 %add, !56, !DIExpression(), !57)
  %incdec.ptr = getelementptr inbounds nuw i8, ptr %p.02, i64 1, !dbg !67
    #dbg_value(ptr %incdec.ptr, !58, !DIExpression(), !60)
  %1 = load i8, ptr %incdec.ptr, align 1, !dbg !68
  %cmp.not = icmp eq i8 %1, 0, !dbg !69
  br i1 %cmp.not, label %for.end, label %for.body, !dbg !61, !llvm.loop !70

for.end:                                          ; preds = %for.body
  %total.0.lcssa = phi i32 [ %add, %for.body ], !dbg !57
  %cmp2 = icmp ne i32 %total.0.lcssa, 2024, !dbg !73
  %cond = zext i1 %cmp2 to i32, !dbg !74
  ret i32 %cond, !dbg !75
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
!35 = !DILocation(line: 10, column: 17, scope: !36)
!36 = distinct !DILexicalBlock(scope: !28, file: !2, line: 10, column: 9)
!37 = !DILocation(line: 11, column: 9, scope: !38)
!38 = distinct !DILexicalBlock(scope: !36, file: !2, line: 10, column: 29)
!39 = !DILocation(line: 12, column: 5, scope: !38)
!40 = !DILocation(line: 13, column: 12, scope: !28)
!41 = !DILocation(line: 13, column: 14, scope: !28)
!42 = !DILocation(line: 13, column: 5, scope: !28)
!43 = distinct !DISubprogram(name: "fail", scope: !2, file: !2, line: 4, type: !44, scopeLine: 4, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !17, retainedNodes: !32)
!44 = !DISubroutineType(types: !45)
!45 = !{null, !46}
!46 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !47, size: 64)
!47 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !4)
!48 = !DILocalVariable(name: "message", arg: 1, scope: !43, file: !2, line: 4, type: !46)
!49 = !DILocation(line: 0, scope: !43)
!50 = !DILocation(line: 5, column: 13, scope: !43)
!51 = !DILocation(line: 5, column: 5, scope: !43)
!52 = !DILocation(line: 6, column: 5, scope: !43)
!53 = distinct !DISubprogram(name: "main", scope: !2, file: !2, line: 16, type: !54, scopeLine: 16, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !17, retainedNodes: !32)
!54 = !DISubroutineType(types: !55)
!55 = !{!31}
!56 = !DILocalVariable(name: "total", scope: !53, file: !2, line: 17, type: !31)
!57 = !DILocation(line: 0, scope: !53)
!58 = !DILocalVariable(name: "p", scope: !59, file: !2, line: 18, type: !46)
!59 = distinct !DILexicalBlock(scope: !53, file: !2, line: 18, column: 5)
!60 = !DILocation(line: 0, scope: !59)
!61 = !DILocation(line: 18, column: 5, scope: !59)
!62 = !DILocation(line: 19, column: 30, scope: !63)
!63 = distinct !DILexicalBlock(scope: !64, file: !2, line: 18, column: 51)
!64 = distinct !DILexicalBlock(scope: !59, file: !2, line: 18, column: 5)
!65 = !DILocation(line: 19, column: 23, scope: !63)
!66 = !DILocation(line: 19, column: 28, scope: !63)
!67 = !DILocation(line: 18, column: 47, scope: !64)
!68 = !DILocation(line: 18, column: 34, scope: !64)
!69 = !DILocation(line: 18, column: 37, scope: !64)
!70 = distinct !{!70, !61, !71, !72}
!71 = !DILocation(line: 20, column: 5, scope: !59)
!72 = !{!"llvm.loop.mustprogress"}
!73 = !DILocation(line: 21, column: 18, scope: !53)
!74 = !DILocation(line: 21, column: 12, scope: !53)
!75 = !DILocation(line: 21, column: 5, scope: !53)
