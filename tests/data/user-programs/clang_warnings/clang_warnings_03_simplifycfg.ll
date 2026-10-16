; ModuleID = '/workspace/out/clang_warnings_02_instcombine.ll'
source_filename = "/workspace/user-programs/clang_warnings.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@__const.last_of_four.four = private unnamed_addr constant [4 x i32] [i32 1, i32 2, i32 3, i32 4], align 16
@.str = private unnamed_addr constant [10 x i8] c"total %d\0A\00", align 1, !dbg !0
@.str.1 = private unnamed_addr constant [9 x i8] c"mean %d\0A\00", align 1, !dbg !7
@__const.main.values = private unnamed_addr constant [6 x i32] [i32 3, i32 -1, i32 4, i32 1, i32 -5, i32 9], align 16

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @count_set_bits(i32 noundef %value) #0 !dbg !25 {
entry:
    #dbg_value(i32 %value, !30, !DIExpression(), !31)
    #dbg_value(i32 0, !32, !DIExpression(), !31)
  br label %while.cond, !dbg !33

while.cond:                                       ; preds = %while.body, %entry
  %count.0 = phi i32 [ 0, %entry ], [ %add, %while.body ], !dbg !31
  %value.addr.0 = phi i32 [ %value, %entry ], [ %shr, %while.body ]
    #dbg_value(i32 %value.addr.0, !30, !DIExpression(), !31)
    #dbg_value(i32 %count.0, !32, !DIExpression(), !31)
  %and = and i32 %value.addr.0, 1, !dbg !34
    #dbg_value(i32 %and, !35, !DIExpression(), !31)
  %tobool.not = icmp eq i32 %and, 0, !dbg !33
  br i1 %tobool.not, label %while.end, label %while.body, !dbg !33

while.body:                                       ; preds = %while.cond
  %add = add i32 %count.0, %and, !dbg !36
    #dbg_value(i32 %add, !32, !DIExpression(), !31)
  %shr = lshr i32 %value.addr.0, 1, !dbg !38
    #dbg_value(i32 %shr, !30, !DIExpression(), !31)
  br label %while.cond, !dbg !33, !llvm.loop !39

while.end:                                        ; preds = %while.cond
  ret i32 %count.0, !dbg !42
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @sum_to(i32 noundef %limit) #0 !dbg !43 {
entry:
    #dbg_value(i32 %limit, !46, !DIExpression(), !47)
    #dbg_value(i32 0, !48, !DIExpression(), !47)
    #dbg_value(i32 0, !49, !DIExpression(), !51)
  br label %for.cond, !dbg !52

for.cond:                                         ; preds = %for.inc, %entry
  %total.0 = phi i32 [ 0, %entry ], [ %add1, %for.inc ], !dbg !47
  %i.0 = phi i32 [ 0, %entry ], [ %inc, %for.inc ], !dbg !53
    #dbg_value(i32 %i.0, !49, !DIExpression(), !51)
    #dbg_value(i32 %total.0, !48, !DIExpression(), !47)
  %cmp = icmp slt i32 %i.0, %limit, !dbg !54
  br i1 %cmp, label %for.inc, label %for.end, !dbg !56

for.inc:                                          ; preds = %for.cond
    #dbg_value(!DIArgList(i32 %total.0, i32 %i.0), !48, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_plus, DW_OP_stack_value), !47)
  %add1 = add nuw nsw i32 %total.0, %i.0, !dbg !57
    #dbg_value(i32 %add1, !48, !DIExpression(), !47)
  %inc = add nuw nsw i32 %i.0, 1, !dbg !59
    #dbg_value(i32 %inc, !49, !DIExpression(), !51)
  br label %for.cond, !dbg !60, !llvm.loop !61

for.end:                                          ; preds = %for.cond
  ret i32 %total.0, !dbg !63
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @is_same(i32 noundef %value) #0 !dbg !64 {
entry:
    #dbg_value(i32 %value, !65, !DIExpression(), !66)
  ret i32 1, !dbg !67
}

; Function Attrs: noinline nounwind uwtable
define dso_local zeroext i8 @small_constant() #0 !dbg !68 {
entry:
    #dbg_value(i8 44, !72, !DIExpression(), !73)
  ret i8 44, !dbg !74
}

; Function Attrs: noinline nounwind uwtable
define dso_local i64 @wide_shift(i32 noundef %value) #0 !dbg !75 {
entry:
    #dbg_value(i32 %value, !79, !DIExpression(), !80)
  ret i64 poison, !dbg !81
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @first_positive(ptr noundef %values, i32 noundef %count) #0 !dbg !82 {
entry:
    #dbg_value(ptr %values, !87, !DIExpression(), !88)
    #dbg_value(i32 %count, !89, !DIExpression(), !88)
    #dbg_value(i32 0, !90, !DIExpression(), !92)
  br label %for.cond, !dbg !93

for.cond:                                         ; preds = %for.inc, %entry
  %i.0 = phi i32 [ 0, %entry ], [ %inc, %for.inc ], !dbg !94
    #dbg_value(i32 %i.0, !90, !DIExpression(), !92)
  %cmp = icmp slt i32 %i.0, %count, !dbg !95
  br i1 %cmp, label %for.body, label %return, !dbg !97

for.body:                                         ; preds = %for.cond
  %idxprom = zext nneg i32 %i.0 to i64, !dbg !98
  %arrayidx = getelementptr inbounds nuw i32, ptr %values, i64 %idxprom, !dbg !98
  %0 = load i32, ptr %arrayidx, align 4, !dbg !98
  %cmp1 = icmp sgt i32 %0, 0, !dbg !101
    #dbg_value(i1 %cmp1, !102, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 32, DW_ATE_unsigned, DW_OP_stack_value), !88)
  br i1 %cmp1, label %if.then, label %for.inc, !dbg !103

if.then:                                          ; preds = %for.body
  %idxprom2 = zext nneg i32 %i.0 to i64, !dbg !104
  %arrayidx3 = getelementptr inbounds nuw i32, ptr %values, i64 %idxprom2, !dbg !104
  %1 = load i32, ptr %arrayidx3, align 4, !dbg !104
  br label %return, !dbg !106

for.inc:                                          ; preds = %for.body
  %inc = add nuw nsw i32 %i.0, 1, !dbg !107
    #dbg_value(i32 %inc, !90, !DIExpression(), !92)
  br label %for.cond, !dbg !108, !llvm.loop !109

return:                                           ; preds = %for.cond, %if.then
  %retval.0 = phi i32 [ %1, %if.then ], [ 0, %for.cond ], !dbg !88
  ret i32 %retval.0, !dbg !111
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @skip_empty(i32 noundef %value) #0 !dbg !112 {
entry:
    #dbg_value(i32 %value, !113, !DIExpression(), !114)
  %cmp = icmp sgt i32 %value, 10, !dbg !115
  ret i32 %value, !dbg !117
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @truncated_half() #0 !dbg !118 {
entry:
    #dbg_value(i32 2, !120, !DIExpression(), !121)
  ret i32 2, !dbg !122
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @last_of_four() #0 !dbg !123 {
entry:
    #dbg_declare(ptr @__const.last_of_four.four, !124, !DIExpression(), !128)
  ret i32 poison, !dbg !129
}

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @not_equal(i32 noundef %a, i32 noundef %b) #0 !dbg !130 {
entry:
    #dbg_value(i32 %a, !133, !DIExpression(), !134)
    #dbg_value(i32 %b, !135, !DIExpression(), !134)
  %tobool.not = icmp eq i32 %a, 0, !dbg !136
  %lnot.ext = zext i1 %tobool.not to i32, !dbg !136
  %cmp = icmp eq i32 %b, %lnot.ext, !dbg !138
  %. = select i1 %cmp, i32 1, i32 0, !dbg !134
  ret i32 %., !dbg !139
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @array_size(ptr noundef %values) #0 !dbg !140 {
entry:
    #dbg_value(ptr %values, !144, !DIExpression(), !145)
  ret i32 2, !dbg !146
}

; Function Attrs: noinline nounwind uwtable
define dso_local void @print_total(i64 noundef %total, double noundef %mean) #0 !dbg !147 {
entry:
    #dbg_value(i64 %total, !151, !DIExpression(), !152)
    #dbg_value(double %mean, !153, !DIExpression(), !152)
  %call = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i64 noundef %total) #3, !dbg !154
  %call1 = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.1, double noundef %mean) #3, !dbg !155
  ret void, !dbg !156
}

declare i32 @printf(ptr noundef, ...) #2

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @scaled_sum(ptr noundef %values, i32 noundef %count) #0 !dbg !157 {
entry:
    #dbg_value(ptr %values, !158, !DIExpression(), !159)
    #dbg_value(i32 %count, !160, !DIExpression(), !159)
    #dbg_value(i32 0, !161, !DIExpression(), !159)
    #dbg_value(i32 0, !162, !DIExpression(), !164)
  br label %for.cond, !dbg !165

for.cond:                                         ; preds = %for.body, %entry
  %total.0 = phi i32 [ 0, %entry ], [ %add, %for.body ], !dbg !159
  %i.0 = phi i32 [ 0, %entry ], [ %inc, %for.body ], !dbg !166
    #dbg_value(i32 %i.0, !162, !DIExpression(), !164)
    #dbg_value(i32 %total.0, !161, !DIExpression(), !159)
  %cmp = icmp slt i32 %i.0, %count, !dbg !167
  br i1 %cmp, label %for.body, label %for.end, !dbg !169

for.body:                                         ; preds = %for.cond
  %idxprom = zext nneg i32 %i.0 to i64, !dbg !170
  %arrayidx = getelementptr inbounds nuw i32, ptr %values, i64 %idxprom, !dbg !170
  %0 = load i32, ptr %arrayidx, align 4, !dbg !170
  %mul = shl nsw i32 %0, 1, !dbg !173
  %add = add nsw i32 %total.0, %mul, !dbg !174
    #dbg_value(i32 %add, !161, !DIExpression(), !159)
  %tobool.not = icmp eq i32 %add, 0, !dbg !175
  %inc = add nuw nsw i32 %i.0, 1, !dbg !176
    #dbg_value(i32 %inc, !162, !DIExpression(), !164)
  br label %for.cond, !dbg !177, !llvm.loop !178

for.end:                                          ; preds = %for.cond
  ret i32 %total.0, !dbg !180
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @clamp(i32 noundef %value) #0 !dbg !181 {
entry:
    #dbg_value(i32 %value, !182, !DIExpression(), !183)
    #dbg_value(i8 56, !184, !DIExpression(), !183)
    #dbg_value(i8 -56, !185, !DIExpression(), !183)
  %cmp = icmp slt i32 %value, 56, !dbg !186
  %retval.0 = select i1 %cmp, i32 56, i32 -56, !dbg !186
  ret i32 %retval.0, !dbg !188
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @max_of(ptr noundef %values, i32 noundef %count) #0 !dbg !189 {
entry:
    #dbg_value(ptr %values, !190, !DIExpression(), !191)
    #dbg_value(i32 %count, !192, !DIExpression(), !191)
  %0 = load i32, ptr %values, align 4, !dbg !193
    #dbg_value(i32 %0, !194, !DIExpression(), !191)
    #dbg_value(i32 1, !195, !DIExpression(), !197)
  br label %for.cond, !dbg !198

for.cond:                                         ; preds = %cond.end, %entry
  %best.0 = phi i32 [ %0, %entry ], [ %cond, %cond.end ], !dbg !191
  %i.0 = phi i32 [ 1, %entry ], [ %inc, %cond.end ], !dbg !199
    #dbg_value(i32 %i.0, !195, !DIExpression(), !197)
    #dbg_value(i32 %best.0, !194, !DIExpression(), !191)
  %cmp = icmp slt i32 %i.0, %count, !dbg !200
  br i1 %cmp, label %for.body, label %for.end, !dbg !202

for.body:                                         ; preds = %for.cond
  %idxprom = zext nneg i32 %i.0 to i64, !dbg !203
  %arrayidx1 = getelementptr inbounds nuw i32, ptr %values, i64 %idxprom, !dbg !203
  %1 = load i32, ptr %arrayidx1, align 4, !dbg !203
  %cmp2 = icmp sgt i32 %1, %best.0, !dbg !206
  br i1 %cmp2, label %cond.true, label %cond.end, !dbg !203

cond.true:                                        ; preds = %for.body
  %idxprom3 = zext nneg i32 %i.0 to i64, !dbg !207
  %arrayidx4 = getelementptr inbounds nuw i32, ptr %values, i64 %idxprom3, !dbg !207
  %2 = load i32, ptr %arrayidx4, align 4, !dbg !207
  br label %cond.end, !dbg !203

cond.end:                                         ; preds = %for.body, %cond.true
  %cond = phi i32 [ %2, %cond.true ], [ %best.0, %for.body ], !dbg !203
    #dbg_value(i32 %cond, !194, !DIExpression(), !191)
  %tobool.not = icmp eq i32 %cond, 0, !dbg !208
  %inc = add nuw nsw i32 %i.0, 1, !dbg !209
    #dbg_value(i32 %inc, !195, !DIExpression(), !197)
  br label %for.cond, !dbg !210, !llvm.loop !211

for.end:                                          ; preds = %for.cond
  ret i32 %best.0, !dbg !213
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @bump(i32 noundef %i) #0 !dbg !214 {
entry:
    #dbg_value(i32 %i, !215, !DIExpression(), !216)
    #dbg_value(i32 %i, !215, !DIExpression(DW_OP_plus_uconst, 1, DW_OP_stack_value), !216)
    #dbg_value(i32 %i, !215, !DIExpression(DW_OP_plus_uconst, 1, DW_OP_stack_value), !216)
  %add = add nsw i32 %i, 1, !dbg !217
    #dbg_value(i32 %add, !215, !DIExpression(), !216)
  ret i32 %add, !dbg !218
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @main() #0 !dbg !219 {
entry:
  %values = alloca [6 x i32], align 16
    #dbg_declare(ptr %values, !220, !DIExpression(), !224)
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(24) %values, ptr noundef nonnull align 16 dereferenceable(24) @__const.main.values, i64 24, i1 false), !dbg !224
  %call = call i32 @sum_to(i32 noundef 10), !dbg !225
  %conv = sext i32 %call to i64, !dbg !225
  call void @print_total(i64 noundef %conv, double noundef 2.500000e+00), !dbg !226
  %call1 = call i32 @first_positive(ptr noundef nonnull %values, i32 noundef 6), !dbg !227
  %call3 = call i32 @max_of(ptr noundef nonnull %values, i32 noundef 6), !dbg !228
  %add = add nsw i32 %call1, %call3, !dbg !229
  %call5 = call i32 @scaled_sum(ptr noundef nonnull %values, i32 noundef 6), !dbg !230
  %add6 = add nsw i32 %add, %call5, !dbg !231
  %arrayidx = getelementptr inbounds nuw i8, ptr %values, i64 20, !dbg !232
  %0 = load i32, ptr %arrayidx, align 4, !dbg !232
  %call7 = call i32 @clamp(i32 noundef %0), !dbg !233
  %add8 = add nsw i32 %add6, %call7, !dbg !234
  %call9 = call i32 @count_set_bits(i32 noundef 255), !dbg !235
  %add10 = add nsw i32 %add8, %call9, !dbg !236
  %call11 = call i32 @is_same(i32 noundef 1), !dbg !237
  %add12 = add nsw i32 %add10, %call11, !dbg !238
  %call13 = call zeroext i8 @small_constant(), !dbg !239
  %conv14 = zext i8 %call13 to i32, !dbg !239
  %add15 = add nsw i32 %add12, %conv14, !dbg !240
  %call16 = call i64 @wide_shift(i32 noundef 1), !dbg !241
  %conv17 = trunc i64 %call16 to i32, !dbg !242
  %add18 = add nsw i32 %add15, %conv17, !dbg !243
  %call19 = call i32 @skip_empty(i32 noundef 3), !dbg !244
  %add20 = add nsw i32 %add18, %call19, !dbg !245
  %call21 = call i32 @truncated_half(), !dbg !246
  %add22 = add nsw i32 %add20, %call21, !dbg !247
  %call23 = call i32 @last_of_four(), !dbg !248
  %add24 = add nsw i32 %add22, %call23, !dbg !249
  %call25 = call i32 @not_equal(i32 noundef 1, i32 noundef 2), !dbg !250
  %add26 = add nsw i32 %add24, %call25, !dbg !251
  %call28 = call i32 @array_size(ptr noundef nonnull %values), !dbg !252
  %add29 = add nsw i32 %add26, %call28, !dbg !253
  %call30 = call i32 @bump(i32 noundef 2), !dbg !254
  %add31 = add nsw i32 %add29, %call30, !dbg !255
  ret i32 %add31, !dbg !256
}

attributes #0 = { noinline nounwind uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }

!llvm.dbg.cu = !{!12}
!llvm.module.flags = !{!17, !18, !19, !20, !21, !22, !23}
!llvm.ident = !{!24}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(scope: null, file: !2, line: 73, type: !3, isLocal: true, isDefinition: true)
!2 = !DIFile(filename: "user-programs/clang_warnings.c", directory: "/workspace", checksumkind: CSK_MD5, checksum: "4220953798334ebd83620e81dd73d814")
!3 = !DICompositeType(tag: DW_TAG_array_type, baseType: !4, size: 80, elements: !5)
!4 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!5 = !{!6}
!6 = !DISubrange(count: 10)
!7 = !DIGlobalVariableExpression(var: !8, expr: !DIExpression())
!8 = distinct !DIGlobalVariable(scope: null, file: !2, line: 74, type: !9, isLocal: true, isDefinition: true)
!9 = !DICompositeType(tag: DW_TAG_array_type, baseType: !4, size: 72, elements: !10)
!10 = !{!11}
!11 = !DISubrange(count: 9)
!12 = distinct !DICompileUnit(language: DW_LANG_C11, file: !13, producer: "clang version 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, retainedTypes: !14, globals: !16, splitDebugInlining: false, nameTableKind: None)
!13 = !DIFile(filename: "/workspace/user-programs/clang_warnings.c", directory: "/workspace", checksumkind: CSK_MD5, checksum: "4220953798334ebd83620e81dd73d814")
!14 = !{!15}
!15 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!16 = !{!0, !7}
!17 = !{i32 7, !"Dwarf Version", i32 5}
!18 = !{i32 2, !"Debug Info Version", i32 3}
!19 = !{i32 1, !"wchar_size", i32 4}
!20 = !{i32 8, !"PIC Level", i32 2}
!21 = !{i32 7, !"PIE Level", i32 2}
!22 = !{i32 7, !"uwtable", i32 2}
!23 = !{i32 7, !"frame-pointer", i32 2}
!24 = !{!"clang version 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)"}
!25 = distinct !DISubprogram(name: "count_set_bits", scope: !2, file: !2, line: 4, type: !26, scopeLine: 4, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!26 = !DISubroutineType(types: !27)
!27 = !{!15, !28}
!28 = !DIBasicType(name: "unsigned int", size: 32, encoding: DW_ATE_unsigned)
!29 = !{}
!30 = !DILocalVariable(name: "value", arg: 1, scope: !25, file: !2, line: 4, type: !28)
!31 = !DILocation(line: 0, scope: !25)
!32 = !DILocalVariable(name: "count", scope: !25, file: !2, line: 5, type: !15)
!33 = !DILocation(line: 7, column: 5, scope: !25)
!34 = !DILocation(line: 7, column: 24, scope: !25)
!35 = !DILocalVariable(name: "bit", scope: !25, file: !2, line: 6, type: !28)
!36 = !DILocation(line: 8, column: 15, scope: !37)
!37 = distinct !DILexicalBlock(scope: !25, file: !2, line: 7, column: 30)
!38 = !DILocation(line: 9, column: 15, scope: !37)
!39 = distinct !{!39, !33, !40, !41}
!40 = !DILocation(line: 10, column: 5, scope: !25)
!41 = !{!"llvm.loop.mustprogress"}
!42 = !DILocation(line: 11, column: 5, scope: !25)
!43 = distinct !DISubprogram(name: "sum_to", scope: !2, file: !2, line: 14, type: !44, scopeLine: 14, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!44 = !DISubroutineType(types: !45)
!45 = !{!15, !15}
!46 = !DILocalVariable(name: "limit", arg: 1, scope: !43, file: !2, line: 14, type: !15)
!47 = !DILocation(line: 0, scope: !43)
!48 = !DILocalVariable(name: "total", scope: !43, file: !2, line: 15, type: !15)
!49 = !DILocalVariable(name: "i", scope: !50, file: !2, line: 16, type: !15)
!50 = distinct !DILexicalBlock(scope: !43, file: !2, line: 16, column: 5)
!51 = !DILocation(line: 0, scope: !50)
!52 = !DILocation(line: 16, column: 10, scope: !50)
!53 = !DILocation(line: 16, scope: !50)
!54 = !DILocation(line: 16, column: 23, scope: !55)
!55 = distinct !DILexicalBlock(scope: !50, file: !2, line: 16, column: 5)
!56 = !DILocation(line: 16, column: 5, scope: !50)
!57 = !DILocation(line: 18, column: 15, scope: !58)
!58 = distinct !DILexicalBlock(scope: !55, file: !2, line: 16, column: 37)
!59 = !DILocation(line: 16, column: 33, scope: !55)
!60 = !DILocation(line: 16, column: 5, scope: !55)
!61 = distinct !{!61, !56, !62, !41}
!62 = !DILocation(line: 19, column: 5, scope: !50)
!63 = !DILocation(line: 20, column: 5, scope: !43)
!64 = distinct !DISubprogram(name: "is_same", scope: !2, file: !2, line: 23, type: !44, scopeLine: 23, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!65 = !DILocalVariable(name: "value", arg: 1, scope: !64, file: !2, line: 23, type: !15)
!66 = !DILocation(line: 0, scope: !64)
!67 = !DILocation(line: 24, column: 5, scope: !64)
!68 = distinct !DISubprogram(name: "small_constant", scope: !2, file: !2, line: 27, type: !69, scopeLine: 27, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!69 = !DISubroutineType(types: !70)
!70 = !{!71}
!71 = !DIBasicType(name: "unsigned char", size: 8, encoding: DW_ATE_unsigned_char)
!72 = !DILocalVariable(name: "byte", scope: !68, file: !2, line: 28, type: !71)
!73 = !DILocation(line: 0, scope: !68)
!74 = !DILocation(line: 29, column: 5, scope: !68)
!75 = distinct !DISubprogram(name: "wide_shift", scope: !2, file: !2, line: 32, type: !76, scopeLine: 32, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!76 = !DISubroutineType(types: !77)
!77 = !{!78, !15}
!78 = !DIBasicType(name: "long", size: 64, encoding: DW_ATE_signed)
!79 = !DILocalVariable(name: "value", arg: 1, scope: !75, file: !2, line: 32, type: !15)
!80 = !DILocation(line: 0, scope: !75)
!81 = !DILocation(line: 33, column: 5, scope: !75)
!82 = distinct !DISubprogram(name: "first_positive", scope: !2, file: !2, line: 36, type: !83, scopeLine: 36, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!83 = !DISubroutineType(types: !84)
!84 = !{!15, !85, !15}
!85 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !86, size: 64)
!86 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !15)
!87 = !DILocalVariable(name: "values", arg: 1, scope: !82, file: !2, line: 36, type: !85)
!88 = !DILocation(line: 0, scope: !82)
!89 = !DILocalVariable(name: "count", arg: 2, scope: !82, file: !2, line: 36, type: !15)
!90 = !DILocalVariable(name: "i", scope: !91, file: !2, line: 38, type: !15)
!91 = distinct !DILexicalBlock(scope: !82, file: !2, line: 38, column: 5)
!92 = !DILocation(line: 0, scope: !91)
!93 = !DILocation(line: 38, column: 10, scope: !91)
!94 = !DILocation(line: 38, scope: !91)
!95 = !DILocation(line: 38, column: 23, scope: !96)
!96 = distinct !DILexicalBlock(scope: !91, file: !2, line: 38, column: 5)
!97 = !DILocation(line: 38, column: 5, scope: !91)
!98 = !DILocation(line: 39, column: 21, scope: !99)
!99 = distinct !DILexicalBlock(scope: !100, file: !2, line: 39, column: 13)
!100 = distinct !DILexicalBlock(scope: !96, file: !2, line: 38, column: 37)
!101 = !DILocation(line: 39, column: 31, scope: !99)
!102 = !DILocalVariable(name: "found", scope: !82, file: !2, line: 37, type: !15)
!103 = !DILocation(line: 39, column: 19, scope: !99)
!104 = !DILocation(line: 40, column: 20, scope: !105)
!105 = distinct !DILexicalBlock(scope: !99, file: !2, line: 39, column: 36)
!106 = !DILocation(line: 40, column: 13, scope: !105)
!107 = !DILocation(line: 38, column: 33, scope: !96)
!108 = !DILocation(line: 38, column: 5, scope: !96)
!109 = distinct !{!109, !97, !110, !41}
!110 = !DILocation(line: 42, column: 5, scope: !91)
!111 = !DILocation(line: 44, column: 1, scope: !82)
!112 = distinct !DISubprogram(name: "skip_empty", scope: !2, file: !2, line: 46, type: !44, scopeLine: 46, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!113 = !DILocalVariable(name: "value", arg: 1, scope: !112, file: !2, line: 46, type: !15)
!114 = !DILocation(line: 0, scope: !112)
!115 = !DILocation(line: 47, column: 15, scope: !116)
!116 = distinct !DILexicalBlock(scope: !112, file: !2, line: 47, column: 9)
!117 = !DILocation(line: 48, column: 5, scope: !112)
!118 = distinct !DISubprogram(name: "truncated_half", scope: !2, file: !2, line: 51, type: !119, scopeLine: 51, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!119 = !DISubroutineType(types: !14)
!120 = !DILocalVariable(name: "half", scope: !118, file: !2, line: 52, type: !15)
!121 = !DILocation(line: 0, scope: !118)
!122 = !DILocation(line: 53, column: 5, scope: !118)
!123 = distinct !DISubprogram(name: "last_of_four", scope: !2, file: !2, line: 56, type: !119, scopeLine: 56, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!124 = !DILocalVariable(name: "four", scope: !123, file: !2, line: 57, type: !125)
!125 = !DICompositeType(tag: DW_TAG_array_type, baseType: !15, size: 128, elements: !126)
!126 = !{!127}
!127 = !DISubrange(count: 4)
!128 = !DILocation(line: 57, column: 9, scope: !123)
!129 = !DILocation(line: 58, column: 5, scope: !123)
!130 = distinct !DISubprogram(name: "not_equal", scope: !2, file: !2, line: 61, type: !131, scopeLine: 61, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!131 = !DISubroutineType(types: !132)
!132 = !{!15, !15, !15}
!133 = !DILocalVariable(name: "a", arg: 1, scope: !130, file: !2, line: 61, type: !15)
!134 = !DILocation(line: 0, scope: !130)
!135 = !DILocalVariable(name: "b", arg: 2, scope: !130, file: !2, line: 61, type: !15)
!136 = !DILocation(line: 62, column: 9, scope: !137)
!137 = distinct !DILexicalBlock(scope: !130, file: !2, line: 62, column: 9)
!138 = !DILocation(line: 62, column: 12, scope: !137)
!139 = !DILocation(line: 66, column: 1, scope: !130)
!140 = distinct !DISubprogram(name: "array_size", scope: !2, file: !2, line: 68, type: !141, scopeLine: 68, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!141 = !DISubroutineType(types: !142)
!142 = !{!15, !143}
!143 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !15, size: 64)
!144 = !DILocalVariable(name: "values", arg: 1, scope: !140, file: !2, line: 68, type: !143)
!145 = !DILocation(line: 0, scope: !140)
!146 = !DILocation(line: 69, column: 5, scope: !140)
!147 = distinct !DISubprogram(name: "print_total", scope: !2, file: !2, line: 72, type: !148, scopeLine: 72, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!148 = !DISubroutineType(types: !149)
!149 = !{null, !78, !150}
!150 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!151 = !DILocalVariable(name: "total", arg: 1, scope: !147, file: !2, line: 72, type: !78)
!152 = !DILocation(line: 0, scope: !147)
!153 = !DILocalVariable(name: "mean", arg: 2, scope: !147, file: !2, line: 72, type: !150)
!154 = !DILocation(line: 73, column: 5, scope: !147)
!155 = !DILocation(line: 74, column: 5, scope: !147)
!156 = !DILocation(line: 75, column: 1, scope: !147)
!157 = distinct !DISubprogram(name: "scaled_sum", scope: !2, file: !2, line: 77, type: !83, scopeLine: 77, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!158 = !DILocalVariable(name: "values", arg: 1, scope: !157, file: !2, line: 77, type: !85)
!159 = !DILocation(line: 0, scope: !157)
!160 = !DILocalVariable(name: "count", arg: 2, scope: !157, file: !2, line: 77, type: !15)
!161 = !DILocalVariable(name: "total", scope: !157, file: !2, line: 78, type: !15)
!162 = !DILocalVariable(name: "i", scope: !163, file: !2, line: 79, type: !15)
!163 = distinct !DILexicalBlock(scope: !157, file: !2, line: 79, column: 5)
!164 = !DILocation(line: 0, scope: !163)
!165 = !DILocation(line: 79, column: 10, scope: !163)
!166 = !DILocation(line: 79, scope: !163)
!167 = !DILocation(line: 79, column: 23, scope: !168)
!168 = distinct !DILexicalBlock(scope: !163, file: !2, line: 79, column: 5)
!169 = !DILocation(line: 79, column: 5, scope: !163)
!170 = !DILocation(line: 80, column: 29, scope: !171)
!171 = distinct !DILexicalBlock(scope: !172, file: !2, line: 80, column: 13)
!172 = distinct !DILexicalBlock(scope: !168, file: !2, line: 79, column: 37)
!173 = !DILocation(line: 80, column: 39, scope: !171)
!174 = !DILocation(line: 80, column: 27, scope: !171)
!175 = !DILocation(line: 80, column: 19, scope: !171)
!176 = !DILocation(line: 79, column: 33, scope: !168)
!177 = !DILocation(line: 79, column: 5, scope: !168)
!178 = distinct !{!178, !169, !179, !41}
!179 = !DILocation(line: 83, column: 5, scope: !163)
!180 = !DILocation(line: 84, column: 5, scope: !157)
!181 = distinct !DISubprogram(name: "clamp", scope: !2, file: !2, line: 87, type: !44, scopeLine: 87, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!182 = !DILocalVariable(name: "value", arg: 1, scope: !181, file: !2, line: 87, type: !15)
!183 = !DILocation(line: 0, scope: !181)
!184 = !DILocalVariable(name: "low", scope: !181, file: !2, line: 88, type: !4)
!185 = !DILocalVariable(name: "high", scope: !181, file: !2, line: 89, type: !4)
!186 = !DILocation(line: 90, column: 15, scope: !187)
!187 = distinct !DILexicalBlock(scope: !181, file: !2, line: 90, column: 9)
!188 = !DILocation(line: 97, column: 1, scope: !181)
!189 = distinct !DISubprogram(name: "max_of", scope: !2, file: !2, line: 99, type: !83, scopeLine: 99, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!190 = !DILocalVariable(name: "values", arg: 1, scope: !189, file: !2, line: 99, type: !85)
!191 = !DILocation(line: 0, scope: !189)
!192 = !DILocalVariable(name: "count", arg: 2, scope: !189, file: !2, line: 99, type: !15)
!193 = !DILocation(line: 100, column: 16, scope: !189)
!194 = !DILocalVariable(name: "best", scope: !189, file: !2, line: 100, type: !15)
!195 = !DILocalVariable(name: "i", scope: !196, file: !2, line: 101, type: !15)
!196 = distinct !DILexicalBlock(scope: !189, file: !2, line: 101, column: 5)
!197 = !DILocation(line: 0, scope: !196)
!198 = !DILocation(line: 101, column: 10, scope: !196)
!199 = !DILocation(line: 101, scope: !196)
!200 = !DILocation(line: 101, column: 23, scope: !201)
!201 = distinct !DILexicalBlock(scope: !196, file: !2, line: 101, column: 5)
!202 = !DILocation(line: 101, column: 5, scope: !196)
!203 = !DILocation(line: 102, column: 20, scope: !204)
!204 = distinct !DILexicalBlock(scope: !205, file: !2, line: 102, column: 13)
!205 = distinct !DILexicalBlock(scope: !201, file: !2, line: 101, column: 37)
!206 = !DILocation(line: 102, column: 30, scope: !204)
!207 = !DILocation(line: 102, column: 39, scope: !204)
!208 = !DILocation(line: 102, column: 18, scope: !204)
!209 = !DILocation(line: 101, column: 33, scope: !201)
!210 = !DILocation(line: 101, column: 5, scope: !201)
!211 = distinct !{!211, !202, !212, !41}
!212 = !DILocation(line: 105, column: 5, scope: !196)
!213 = !DILocation(line: 106, column: 5, scope: !189)
!214 = distinct !DISubprogram(name: "bump", scope: !2, file: !2, line: 109, type: !44, scopeLine: 109, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!215 = !DILocalVariable(name: "i", arg: 1, scope: !214, file: !2, line: 109, type: !15)
!216 = !DILocation(line: 0, scope: !214)
!217 = !DILocation(line: 110, column: 13, scope: !214)
!218 = !DILocation(line: 111, column: 5, scope: !214)
!219 = distinct !DISubprogram(name: "main", scope: !2, file: !2, line: 114, type: !119, scopeLine: 114, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!220 = !DILocalVariable(name: "values", scope: !219, file: !2, line: 115, type: !221)
!221 = !DICompositeType(tag: DW_TAG_array_type, baseType: !15, size: 192, elements: !222)
!222 = !{!223}
!223 = !DISubrange(count: 6)
!224 = !DILocation(line: 115, column: 9, scope: !219)
!225 = !DILocation(line: 116, column: 17, scope: !219)
!226 = !DILocation(line: 116, column: 5, scope: !219)
!227 = !DILocation(line: 117, column: 12, scope: !219)
!228 = !DILocation(line: 117, column: 40, scope: !219)
!229 = !DILocation(line: 117, column: 38, scope: !219)
!230 = !DILocation(line: 117, column: 60, scope: !219)
!231 = !DILocation(line: 117, column: 58, scope: !219)
!232 = !DILocation(line: 117, column: 90, scope: !219)
!233 = !DILocation(line: 117, column: 84, scope: !219)
!234 = !DILocation(line: 117, column: 82, scope: !219)
!235 = !DILocation(line: 118, column: 11, scope: !219)
!236 = !DILocation(line: 118, column: 9, scope: !219)
!237 = !DILocation(line: 118, column: 34, scope: !219)
!238 = !DILocation(line: 118, column: 32, scope: !219)
!239 = !DILocation(line: 118, column: 47, scope: !219)
!240 = !DILocation(line: 118, column: 45, scope: !219)
!241 = !DILocation(line: 118, column: 71, scope: !219)
!242 = !DILocation(line: 118, column: 66, scope: !219)
!243 = !DILocation(line: 118, column: 64, scope: !219)
!244 = !DILocation(line: 118, column: 87, scope: !219)
!245 = !DILocation(line: 118, column: 85, scope: !219)
!246 = !DILocation(line: 119, column: 11, scope: !219)
!247 = !DILocation(line: 119, column: 9, scope: !219)
!248 = !DILocation(line: 119, column: 30, scope: !219)
!249 = !DILocation(line: 119, column: 28, scope: !219)
!250 = !DILocation(line: 119, column: 47, scope: !219)
!251 = !DILocation(line: 119, column: 45, scope: !219)
!252 = !DILocation(line: 119, column: 65, scope: !219)
!253 = !DILocation(line: 119, column: 63, scope: !219)
!254 = !DILocation(line: 119, column: 86, scope: !219)
!255 = !DILocation(line: 119, column: 84, scope: !219)
!256 = !DILocation(line: 117, column: 5, scope: !219)
