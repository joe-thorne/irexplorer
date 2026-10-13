; ModuleID = '/workspace/out/ends_in_exit_03_simplifycfg.ll'
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
  %cmp3 = icmp ugt i8 %c, 57
  %or.cond = or i1 %cmp, %cmp3, !dbg !37
  br i1 %or.cond, label %if.then, label %if.end, !dbg !37

if.then:                                          ; preds = %entry
  call void @fail(ptr noundef nonnull @.str), !dbg !38
  br label %if.end, !dbg !40

if.end:                                           ; preds = %if.then, %entry
  %conv5 = sext i8 %c to i32, !dbg !41
  %sub = add nsw i32 %conv5, -48, !dbg !42
  ret i32 %sub, !dbg !43
}

; Function Attrs: noinline nounwind uwtable
define internal void @fail(ptr noundef %message) #0 !dbg !44 {
entry:
    #dbg_value(ptr %message, !49, !DIExpression(), !50)
  %0 = load ptr, ptr @stderr, align 8, !dbg !51
  %call = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %0, ptr noundef nonnull @.str.2, ptr noundef %message) #3, !dbg !52
  call void @exit(i32 noundef 1) #4, !dbg !53
  unreachable, !dbg !53
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @main() #0 !dbg !54 {
entry:
    #dbg_value(i32 0, !57, !DIExpression(), !58)
    #dbg_value(ptr @.str.1, !59, !DIExpression(), !61)
  br label %for.cond, !dbg !62

for.cond:                                         ; preds = %for.body, %entry
  %total.0 = phi i32 [ 0, %entry ], [ %add, %for.body ], !dbg !58
  %p.0 = phi ptr [ @.str.1, %entry ], [ %incdec.ptr, %for.body ], !dbg !63
    #dbg_value(ptr %p.0, !59, !DIExpression(), !61)
    #dbg_value(i32 %total.0, !57, !DIExpression(), !58)
  %0 = load i8, ptr %p.0, align 1, !dbg !64
  %cmp.not = icmp eq i8 %0, 0, !dbg !66
  br i1 %cmp.not, label %for.end, label %for.body, !dbg !67

for.body:                                         ; preds = %for.cond
  %call = call i32 @parse_digit(i8 noundef signext %0), !dbg !68
    #dbg_value(!DIArgList(i32 %total.0, i32 %call), !57, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_constu, 10, DW_OP_mul, DW_OP_LLVM_arg, 1, DW_OP_plus, DW_OP_stack_value), !58)
  %mul = mul nsw i32 %total.0, 10, !dbg !70
    #dbg_value(!DIArgList(i32 %mul, i32 %call), !57, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_plus, DW_OP_stack_value), !58)
  %add = add nsw i32 %mul, %call, !dbg !71
    #dbg_value(i32 %add, !57, !DIExpression(), !58)
  %incdec.ptr = getelementptr inbounds nuw i8, ptr %p.0, i64 1, !dbg !72
    #dbg_value(ptr %incdec.ptr, !59, !DIExpression(), !61)
  br label %for.cond, !dbg !73, !llvm.loop !74

for.end:                                          ; preds = %for.cond
  %cmp2 = icmp ne i32 %total.0, 2024, !dbg !77
  %cond = zext i1 %cmp2 to i32, !dbg !78
  ret i32 %cond, !dbg !79
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
!38 = !DILocation(line: 11, column: 9, scope: !39)
!39 = distinct !DILexicalBlock(scope: !36, file: !2, line: 10, column: 29)
!40 = !DILocation(line: 12, column: 5, scope: !39)
!41 = !DILocation(line: 13, column: 12, scope: !28)
!42 = !DILocation(line: 13, column: 14, scope: !28)
!43 = !DILocation(line: 13, column: 5, scope: !28)
!44 = distinct !DISubprogram(name: "fail", scope: !2, file: !2, line: 4, type: !45, scopeLine: 4, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !17, retainedNodes: !32)
!45 = !DISubroutineType(types: !46)
!46 = !{null, !47}
!47 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !48, size: 64)
!48 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !4)
!49 = !DILocalVariable(name: "message", arg: 1, scope: !44, file: !2, line: 4, type: !47)
!50 = !DILocation(line: 0, scope: !44)
!51 = !DILocation(line: 5, column: 13, scope: !44)
!52 = !DILocation(line: 5, column: 5, scope: !44)
!53 = !DILocation(line: 6, column: 5, scope: !44)
!54 = distinct !DISubprogram(name: "main", scope: !2, file: !2, line: 16, type: !55, scopeLine: 16, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !17, retainedNodes: !32)
!55 = !DISubroutineType(types: !56)
!56 = !{!31}
!57 = !DILocalVariable(name: "total", scope: !54, file: !2, line: 17, type: !31)
!58 = !DILocation(line: 0, scope: !54)
!59 = !DILocalVariable(name: "p", scope: !60, file: !2, line: 18, type: !47)
!60 = distinct !DILexicalBlock(scope: !54, file: !2, line: 18, column: 5)
!61 = !DILocation(line: 0, scope: !60)
!62 = !DILocation(line: 18, column: 10, scope: !60)
!63 = !DILocation(line: 18, scope: !60)
!64 = !DILocation(line: 18, column: 34, scope: !65)
!65 = distinct !DILexicalBlock(scope: !60, file: !2, line: 18, column: 5)
!66 = !DILocation(line: 18, column: 37, scope: !65)
!67 = !DILocation(line: 18, column: 5, scope: !60)
!68 = !DILocation(line: 19, column: 30, scope: !69)
!69 = distinct !DILexicalBlock(scope: !65, file: !2, line: 18, column: 51)
!70 = !DILocation(line: 19, column: 23, scope: !69)
!71 = !DILocation(line: 19, column: 28, scope: !69)
!72 = !DILocation(line: 18, column: 47, scope: !65)
!73 = !DILocation(line: 18, column: 5, scope: !65)
!74 = distinct !{!74, !67, !75, !76}
!75 = !DILocation(line: 20, column: 5, scope: !60)
!76 = !{!"llvm.loop.mustprogress"}
!77 = !DILocation(line: 21, column: 18, scope: !54)
!78 = !DILocation(line: 21, column: 12, scope: !54)
!79 = !DILocation(line: 21, column: 5, scope: !54)
