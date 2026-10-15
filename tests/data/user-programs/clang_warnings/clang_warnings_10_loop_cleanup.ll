; ModuleID = '/workspace/out/clang_warnings_09_indvars.ll'
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
  %and1 = and i32 %value, 1, !dbg !33
  %tobool.not2 = icmp eq i32 %and1, 0, !dbg !34
  br i1 %tobool.not2, label %while.end, label %while.body, !dbg !34

while.body:                                       ; preds = %entry, %while.body
  %and5 = phi i32 [ %and, %while.body ], [ %and1, %entry ]
  %value.addr.04 = phi i32 [ %shr, %while.body ], [ %value, %entry ]
  %count.03 = phi i32 [ %add, %while.body ], [ 0, %entry ]
    #dbg_value(i32 %value.addr.04, !30, !DIExpression(), !31)
    #dbg_value(i32 %count.03, !32, !DIExpression(), !31)
  %add = add i32 %count.03, %and5, !dbg !35
    #dbg_value(i32 %add, !32, !DIExpression(), !31)
  %shr = lshr i32 %value.addr.04, 1, !dbg !37
    #dbg_value(i32 %shr, !30, !DIExpression(), !31)
  %and = and i32 %shr, 1, !dbg !33
    #dbg_value(i32 %and, !38, !DIExpression(), !31)
  %tobool.not = icmp eq i32 %and, 0, !dbg !34
  br i1 %tobool.not, label %while.end, label %while.body, !dbg !34, !llvm.loop !39

while.end:                                        ; preds = %while.body, %entry
  %count.0.lcssa = phi i32 [ 0, %entry ], [ %add, %while.body ], !dbg !31
  ret i32 %count.0.lcssa, !dbg !42
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @sum_to(i32 noundef %limit) #0 !dbg !43 {
entry:
    #dbg_value(i32 %limit, !46, !DIExpression(), !47)
    #dbg_value(i32 0, !48, !DIExpression(), !47)
    #dbg_value(i32 0, !49, !DIExpression(), !51)
  %cmp1 = icmp sgt i32 %limit, 0, !dbg !52
  br i1 %cmp1, label %for.cond.for.end_crit_edge, label %for.end, !dbg !54

for.cond.for.end_crit_edge:                       ; preds = %entry
    #dbg_value(i32 poison, !49, !DIExpression(), !51)
    #dbg_value(!DIArgList(i32 poison, i32 poison), !48, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_plus, DW_OP_stack_value), !47)
    #dbg_value(!DIArgList(i32 poison, i32 poison), !48, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_plus, DW_OP_stack_value), !47)
    #dbg_value(i32 poison, !49, !DIExpression(DW_OP_plus_uconst, 1, DW_OP_stack_value), !51)
  %0 = add nsw i32 %limit, -1, !dbg !54
  %1 = zext i32 %0 to i33, !dbg !54
  %2 = add nsw i32 %limit, -2, !dbg !54
  %3 = zext i32 %2 to i33, !dbg !54
  %4 = mul i33 %1, %3, !dbg !54
  %5 = lshr i33 %4, 1, !dbg !54
  %6 = trunc nuw i33 %5 to i32, !dbg !54
  %7 = add i32 %limit, %6, !dbg !54
  %8 = add i32 %7, -1, !dbg !54
  br label %for.end, !dbg !54

for.end:                                          ; preds = %for.cond.for.end_crit_edge, %entry
  %total.0.lcssa = phi i32 [ %8, %for.cond.for.end_crit_edge ], [ 0, %entry ], !dbg !47
  ret i32 %total.0.lcssa, !dbg !55
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @is_same(i32 noundef %value) #0 !dbg !56 {
entry:
    #dbg_value(i32 %value, !57, !DIExpression(), !58)
  ret i32 1, !dbg !59
}

; Function Attrs: noinline nounwind uwtable
define dso_local zeroext i8 @small_constant() #0 !dbg !60 {
entry:
    #dbg_value(i8 44, !64, !DIExpression(), !65)
  ret i8 44, !dbg !66
}

; Function Attrs: noinline nounwind uwtable
define dso_local i64 @wide_shift(i32 noundef %value) #0 !dbg !67 {
entry:
    #dbg_value(i32 %value, !71, !DIExpression(), !72)
  ret i64 poison, !dbg !73
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @first_positive(ptr noundef %values, i32 noundef %count) #0 !dbg !74 {
entry:
    #dbg_value(ptr %values, !79, !DIExpression(), !80)
    #dbg_value(i32 %count, !81, !DIExpression(), !80)
    #dbg_value(i32 0, !82, !DIExpression(), !84)
  %cmp2 = icmp sgt i32 %count, 0, !dbg !85
  br i1 %cmp2, label %for.body, label %return, !dbg !87

for.cond:                                         ; preds = %for.body
  %inc = add i32 %i.03, 1, !dbg !88
    #dbg_value(i32 %inc, !82, !DIExpression(), !84)
    #dbg_value(i32 %inc, !82, !DIExpression(), !84)
  %exitcond.not = icmp eq i32 %inc, %count, !dbg !85
  br i1 %exitcond.not, label %return, label %for.body, !dbg !87, !llvm.loop !89

for.body:                                         ; preds = %entry, %for.cond
  %i.03 = phi i32 [ %inc, %for.cond ], [ 0, %entry ]
    #dbg_value(i32 %i.03, !82, !DIExpression(), !84)
  %idxprom = zext nneg i32 %i.03 to i64, !dbg !91
  %arrayidx = getelementptr inbounds nuw i32, ptr %values, i64 %idxprom, !dbg !91
  %0 = load i32, ptr %arrayidx, align 4, !dbg !91
  %cmp1 = icmp sgt i32 %0, 0, !dbg !94
    #dbg_value(i1 %cmp1, !95, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 32, DW_ATE_unsigned, DW_OP_stack_value), !80)
    #dbg_value(i32 %i.03, !82, !DIExpression(DW_OP_plus_uconst, 1, DW_OP_stack_value), !84)
  br i1 %cmp1, label %return, label %for.cond, !dbg !96

return:                                           ; preds = %for.cond, %for.body, %entry
  %retval.0 = phi i32 [ %0, %for.body ], [ 0, %entry ], [ 0, %for.cond ], !dbg !80
  ret i32 %retval.0, !dbg !97
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @skip_empty(i32 noundef %value) #0 !dbg !98 {
entry:
    #dbg_value(i32 %value, !99, !DIExpression(), !100)
  ret i32 %value, !dbg !101
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @truncated_half() #0 !dbg !102 {
entry:
    #dbg_value(i32 2, !104, !DIExpression(), !105)
  ret i32 2, !dbg !106
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @last_of_four() #0 !dbg !107 {
entry:
    #dbg_declare(ptr @__const.last_of_four.four, !108, !DIExpression(), !112)
  ret i32 poison, !dbg !113
}

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @not_equal(i32 noundef %a, i32 noundef %b) #0 !dbg !114 {
entry:
    #dbg_value(i32 %a, !117, !DIExpression(), !118)
    #dbg_value(i32 %b, !119, !DIExpression(), !118)
  %tobool.not = icmp eq i32 %a, 0, !dbg !120
  %lnot.ext = zext i1 %tobool.not to i32, !dbg !120
  %cmp = icmp eq i32 %b, %lnot.ext, !dbg !122
  %. = zext i1 %cmp to i32, !dbg !118
  ret i32 %., !dbg !123
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @array_size(ptr noundef %values) #0 !dbg !124 {
entry:
    #dbg_value(ptr %values, !128, !DIExpression(), !129)
  ret i32 2, !dbg !130
}

; Function Attrs: noinline nounwind uwtable
define dso_local void @print_total(i64 noundef %total, double noundef %mean) #0 !dbg !131 {
entry:
    #dbg_value(i64 %total, !135, !DIExpression(), !136)
    #dbg_value(double %mean, !137, !DIExpression(), !136)
  %call = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i64 noundef %total) #4, !dbg !138
  %call1 = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.1, double noundef %mean) #4, !dbg !139
  ret void, !dbg !140
}

declare i32 @printf(ptr noundef, ...) #2

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @scaled_sum(ptr noundef %values, i32 noundef %count) #0 !dbg !141 {
entry:
    #dbg_value(ptr %values, !142, !DIExpression(), !143)
    #dbg_value(i32 %count, !144, !DIExpression(), !143)
    #dbg_value(i32 0, !145, !DIExpression(), !143)
    #dbg_value(i32 0, !146, !DIExpression(), !148)
  %cmp1 = icmp sgt i32 %count, 0, !dbg !149
  br i1 %cmp1, label %for.body.lr.ph, label %for.end, !dbg !151

for.body.lr.ph:                                   ; preds = %entry
  %wide.trip.count = zext nneg i32 %count to i64, !dbg !149
  br label %for.body, !dbg !151

for.body:                                         ; preds = %for.body, %for.body.lr.ph
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.body ], [ 0, %for.body.lr.ph ]
  %total.02 = phi i32 [ %add, %for.body ], [ 0, %for.body.lr.ph ]
    #dbg_value(i64 %indvars.iv, !146, !DIExpression(), !148)
    #dbg_value(i32 %total.02, !145, !DIExpression(), !143)
  %arrayidx = getelementptr inbounds nuw i32, ptr %values, i64 %indvars.iv, !dbg !152
  %0 = load i32, ptr %arrayidx, align 4, !dbg !152
  %mul = shl nsw i32 %0, 1, !dbg !155
  %add = add nsw i32 %total.02, %mul, !dbg !156
    #dbg_value(i32 %add, !145, !DIExpression(), !143)
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !157
    #dbg_value(i64 %indvars.iv.next, !146, !DIExpression(), !148)
  %exitcond.not = icmp eq i64 %indvars.iv.next, %wide.trip.count, !dbg !149
  br i1 %exitcond.not, label %for.end, label %for.body, !dbg !151, !llvm.loop !158

for.end:                                          ; preds = %for.body, %entry
  %total.0.lcssa = phi i32 [ 0, %entry ], [ %add, %for.body ], !dbg !143
  ret i32 %total.0.lcssa, !dbg !160
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @clamp(i32 noundef %value) #0 !dbg !161 {
entry:
    #dbg_value(i32 %value, !162, !DIExpression(), !163)
    #dbg_value(i8 56, !164, !DIExpression(), !163)
    #dbg_value(i8 -56, !165, !DIExpression(), !163)
  %cmp = icmp slt i32 %value, 56, !dbg !166
  %retval.0 = select i1 %cmp, i32 56, i32 -56, !dbg !166
  ret i32 %retval.0, !dbg !168
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @max_of(ptr noundef %values, i32 noundef %count) #0 !dbg !169 {
entry:
    #dbg_value(ptr %values, !170, !DIExpression(), !171)
    #dbg_value(i32 %count, !172, !DIExpression(), !171)
  %0 = load i32, ptr %values, align 4, !dbg !173
    #dbg_value(i32 %0, !174, !DIExpression(), !171)
    #dbg_value(i32 1, !175, !DIExpression(), !177)
  %cmp1 = icmp sgt i32 %count, 1, !dbg !178
  br i1 %cmp1, label %for.body.lr.ph, label %for.end, !dbg !180

for.body.lr.ph:                                   ; preds = %entry
  %wide.trip.count = zext nneg i32 %count to i64, !dbg !178
  br label %for.body, !dbg !180

for.body:                                         ; preds = %for.body, %for.body.lr.ph
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.body ], [ 1, %for.body.lr.ph ]
  %best.02 = phi i32 [ %spec.select, %for.body ], [ %0, %for.body.lr.ph ]
    #dbg_value(i64 %indvars.iv, !175, !DIExpression(), !177)
    #dbg_value(i32 %best.02, !174, !DIExpression(), !171)
  %arrayidx1 = getelementptr inbounds nuw i32, ptr %values, i64 %indvars.iv, !dbg !181
  %1 = load i32, ptr %arrayidx1, align 4, !dbg !181
  %spec.select = call i32 @llvm.smax.i32(i32 %1, i32 %best.02), !dbg !181
    #dbg_value(i32 %spec.select, !174, !DIExpression(), !171)
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !184
    #dbg_value(i64 %indvars.iv.next, !175, !DIExpression(), !177)
  %exitcond.not = icmp eq i64 %indvars.iv.next, %wide.trip.count, !dbg !178
  br i1 %exitcond.not, label %for.end, label %for.body, !dbg !180, !llvm.loop !185

for.end:                                          ; preds = %for.body, %entry
  %best.0.lcssa = phi i32 [ %0, %entry ], [ %spec.select, %for.body ], !dbg !171
  ret i32 %best.0.lcssa, !dbg !187
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @bump(i32 noundef %i) #0 !dbg !188 {
entry:
    #dbg_value(i32 %i, !189, !DIExpression(), !190)
    #dbg_value(i32 %i, !189, !DIExpression(DW_OP_plus_uconst, 1, DW_OP_stack_value), !190)
    #dbg_value(i32 %i, !189, !DIExpression(DW_OP_plus_uconst, 1, DW_OP_stack_value), !190)
  %add = add nsw i32 %i, 1, !dbg !191
    #dbg_value(i32 %add, !189, !DIExpression(), !190)
  ret i32 %add, !dbg !192
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @main() #0 !dbg !193 {
entry:
  %values = alloca [6 x i32], align 16
    #dbg_declare(ptr %values, !194, !DIExpression(), !198)
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(24) %values, ptr noundef nonnull align 16 dereferenceable(24) @__const.main.values, i64 24, i1 false), !dbg !198
  %call = call i32 @sum_to(i32 noundef 10), !dbg !199
  %conv = sext i32 %call to i64, !dbg !199
  call void @print_total(i64 noundef %conv, double noundef 2.500000e+00), !dbg !200
  %call1 = call i32 @first_positive(ptr noundef nonnull %values, i32 noundef 6), !dbg !201
  %call3 = call i32 @max_of(ptr noundef nonnull %values, i32 noundef 6), !dbg !202
  %add = add nsw i32 %call1, %call3, !dbg !203
  %call5 = call i32 @scaled_sum(ptr noundef nonnull %values, i32 noundef 6), !dbg !204
  %add6 = add nsw i32 %add, %call5, !dbg !205
  %arrayidx = getelementptr inbounds nuw i8, ptr %values, i64 20, !dbg !206
  %0 = load i32, ptr %arrayidx, align 4, !dbg !206
  %call7 = call i32 @clamp(i32 noundef %0), !dbg !207
  %add8 = add nsw i32 %add6, %call7, !dbg !208
  %call9 = call i32 @count_set_bits(i32 noundef 255), !dbg !209
  %add10 = add nsw i32 %add8, %call9, !dbg !210
  %call11 = call i32 @is_same(i32 noundef 1), !dbg !211
  %add12 = add nsw i32 %add10, %call11, !dbg !212
  %call13 = call zeroext i8 @small_constant(), !dbg !213
  %conv14 = zext i8 %call13 to i32, !dbg !213
  %add15 = add nsw i32 %add12, %conv14, !dbg !214
  %call16 = call i64 @wide_shift(i32 noundef 1), !dbg !215
  %conv17 = trunc i64 %call16 to i32, !dbg !216
  %add18 = add nsw i32 %add15, %conv17, !dbg !217
  %call19 = call i32 @skip_empty(i32 noundef 3), !dbg !218
  %add20 = add nsw i32 %add18, %call19, !dbg !219
  %call21 = call i32 @truncated_half(), !dbg !220
  %add22 = add nsw i32 %add20, %call21, !dbg !221
  %call23 = call i32 @last_of_four(), !dbg !222
  %add24 = add nsw i32 %add22, %call23, !dbg !223
  %call25 = call i32 @not_equal(i32 noundef 1, i32 noundef 2), !dbg !224
  %add26 = add nsw i32 %add24, %call25, !dbg !225
  %call28 = call i32 @array_size(ptr noundef nonnull %values), !dbg !226
  %add29 = add nsw i32 %add26, %call28, !dbg !227
  %call30 = call i32 @bump(i32 noundef 2), !dbg !228
  %add31 = add nsw i32 %add29, %call30, !dbg !229
  ret i32 %add31, !dbg !230
}

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smax.i32(i32, i32) #3

attributes #0 = { noinline nounwind uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none) }
attributes #4 = { nounwind }

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
!33 = !DILocation(line: 7, column: 24, scope: !25)
!34 = !DILocation(line: 7, column: 5, scope: !25)
!35 = !DILocation(line: 8, column: 15, scope: !36)
!36 = distinct !DILexicalBlock(scope: !25, file: !2, line: 7, column: 30)
!37 = !DILocation(line: 9, column: 15, scope: !36)
!38 = !DILocalVariable(name: "bit", scope: !25, file: !2, line: 6, type: !28)
!39 = distinct !{!39, !34, !40, !41}
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
!52 = !DILocation(line: 16, column: 23, scope: !53)
!53 = distinct !DILexicalBlock(scope: !50, file: !2, line: 16, column: 5)
!54 = !DILocation(line: 16, column: 5, scope: !50)
!55 = !DILocation(line: 20, column: 5, scope: !43)
!56 = distinct !DISubprogram(name: "is_same", scope: !2, file: !2, line: 23, type: !44, scopeLine: 23, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!57 = !DILocalVariable(name: "value", arg: 1, scope: !56, file: !2, line: 23, type: !15)
!58 = !DILocation(line: 0, scope: !56)
!59 = !DILocation(line: 24, column: 5, scope: !56)
!60 = distinct !DISubprogram(name: "small_constant", scope: !2, file: !2, line: 27, type: !61, scopeLine: 27, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!61 = !DISubroutineType(types: !62)
!62 = !{!63}
!63 = !DIBasicType(name: "unsigned char", size: 8, encoding: DW_ATE_unsigned_char)
!64 = !DILocalVariable(name: "byte", scope: !60, file: !2, line: 28, type: !63)
!65 = !DILocation(line: 0, scope: !60)
!66 = !DILocation(line: 29, column: 5, scope: !60)
!67 = distinct !DISubprogram(name: "wide_shift", scope: !2, file: !2, line: 32, type: !68, scopeLine: 32, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!68 = !DISubroutineType(types: !69)
!69 = !{!70, !15}
!70 = !DIBasicType(name: "long", size: 64, encoding: DW_ATE_signed)
!71 = !DILocalVariable(name: "value", arg: 1, scope: !67, file: !2, line: 32, type: !15)
!72 = !DILocation(line: 0, scope: !67)
!73 = !DILocation(line: 33, column: 5, scope: !67)
!74 = distinct !DISubprogram(name: "first_positive", scope: !2, file: !2, line: 36, type: !75, scopeLine: 36, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!75 = !DISubroutineType(types: !76)
!76 = !{!15, !77, !15}
!77 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !78, size: 64)
!78 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !15)
!79 = !DILocalVariable(name: "values", arg: 1, scope: !74, file: !2, line: 36, type: !77)
!80 = !DILocation(line: 0, scope: !74)
!81 = !DILocalVariable(name: "count", arg: 2, scope: !74, file: !2, line: 36, type: !15)
!82 = !DILocalVariable(name: "i", scope: !83, file: !2, line: 38, type: !15)
!83 = distinct !DILexicalBlock(scope: !74, file: !2, line: 38, column: 5)
!84 = !DILocation(line: 0, scope: !83)
!85 = !DILocation(line: 38, column: 23, scope: !86)
!86 = distinct !DILexicalBlock(scope: !83, file: !2, line: 38, column: 5)
!87 = !DILocation(line: 38, column: 5, scope: !83)
!88 = !DILocation(line: 38, column: 33, scope: !86)
!89 = distinct !{!89, !87, !90, !41}
!90 = !DILocation(line: 42, column: 5, scope: !83)
!91 = !DILocation(line: 39, column: 21, scope: !92)
!92 = distinct !DILexicalBlock(scope: !93, file: !2, line: 39, column: 13)
!93 = distinct !DILexicalBlock(scope: !86, file: !2, line: 38, column: 37)
!94 = !DILocation(line: 39, column: 31, scope: !92)
!95 = !DILocalVariable(name: "found", scope: !74, file: !2, line: 37, type: !15)
!96 = !DILocation(line: 39, column: 19, scope: !92)
!97 = !DILocation(line: 44, column: 1, scope: !74)
!98 = distinct !DISubprogram(name: "skip_empty", scope: !2, file: !2, line: 46, type: !44, scopeLine: 46, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!99 = !DILocalVariable(name: "value", arg: 1, scope: !98, file: !2, line: 46, type: !15)
!100 = !DILocation(line: 0, scope: !98)
!101 = !DILocation(line: 48, column: 5, scope: !98)
!102 = distinct !DISubprogram(name: "truncated_half", scope: !2, file: !2, line: 51, type: !103, scopeLine: 51, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!103 = !DISubroutineType(types: !14)
!104 = !DILocalVariable(name: "half", scope: !102, file: !2, line: 52, type: !15)
!105 = !DILocation(line: 0, scope: !102)
!106 = !DILocation(line: 53, column: 5, scope: !102)
!107 = distinct !DISubprogram(name: "last_of_four", scope: !2, file: !2, line: 56, type: !103, scopeLine: 56, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!108 = !DILocalVariable(name: "four", scope: !107, file: !2, line: 57, type: !109)
!109 = !DICompositeType(tag: DW_TAG_array_type, baseType: !15, size: 128, elements: !110)
!110 = !{!111}
!111 = !DISubrange(count: 4)
!112 = !DILocation(line: 57, column: 9, scope: !107)
!113 = !DILocation(line: 58, column: 5, scope: !107)
!114 = distinct !DISubprogram(name: "not_equal", scope: !2, file: !2, line: 61, type: !115, scopeLine: 61, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!115 = !DISubroutineType(types: !116)
!116 = !{!15, !15, !15}
!117 = !DILocalVariable(name: "a", arg: 1, scope: !114, file: !2, line: 61, type: !15)
!118 = !DILocation(line: 0, scope: !114)
!119 = !DILocalVariable(name: "b", arg: 2, scope: !114, file: !2, line: 61, type: !15)
!120 = !DILocation(line: 62, column: 9, scope: !121)
!121 = distinct !DILexicalBlock(scope: !114, file: !2, line: 62, column: 9)
!122 = !DILocation(line: 62, column: 12, scope: !121)
!123 = !DILocation(line: 66, column: 1, scope: !114)
!124 = distinct !DISubprogram(name: "array_size", scope: !2, file: !2, line: 68, type: !125, scopeLine: 68, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!125 = !DISubroutineType(types: !126)
!126 = !{!15, !127}
!127 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !15, size: 64)
!128 = !DILocalVariable(name: "values", arg: 1, scope: !124, file: !2, line: 68, type: !127)
!129 = !DILocation(line: 0, scope: !124)
!130 = !DILocation(line: 69, column: 5, scope: !124)
!131 = distinct !DISubprogram(name: "print_total", scope: !2, file: !2, line: 72, type: !132, scopeLine: 72, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!132 = !DISubroutineType(types: !133)
!133 = !{null, !70, !134}
!134 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!135 = !DILocalVariable(name: "total", arg: 1, scope: !131, file: !2, line: 72, type: !70)
!136 = !DILocation(line: 0, scope: !131)
!137 = !DILocalVariable(name: "mean", arg: 2, scope: !131, file: !2, line: 72, type: !134)
!138 = !DILocation(line: 73, column: 5, scope: !131)
!139 = !DILocation(line: 74, column: 5, scope: !131)
!140 = !DILocation(line: 75, column: 1, scope: !131)
!141 = distinct !DISubprogram(name: "scaled_sum", scope: !2, file: !2, line: 77, type: !75, scopeLine: 77, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!142 = !DILocalVariable(name: "values", arg: 1, scope: !141, file: !2, line: 77, type: !77)
!143 = !DILocation(line: 0, scope: !141)
!144 = !DILocalVariable(name: "count", arg: 2, scope: !141, file: !2, line: 77, type: !15)
!145 = !DILocalVariable(name: "total", scope: !141, file: !2, line: 78, type: !15)
!146 = !DILocalVariable(name: "i", scope: !147, file: !2, line: 79, type: !15)
!147 = distinct !DILexicalBlock(scope: !141, file: !2, line: 79, column: 5)
!148 = !DILocation(line: 0, scope: !147)
!149 = !DILocation(line: 79, column: 23, scope: !150)
!150 = distinct !DILexicalBlock(scope: !147, file: !2, line: 79, column: 5)
!151 = !DILocation(line: 79, column: 5, scope: !147)
!152 = !DILocation(line: 80, column: 29, scope: !153)
!153 = distinct !DILexicalBlock(scope: !154, file: !2, line: 80, column: 13)
!154 = distinct !DILexicalBlock(scope: !150, file: !2, line: 79, column: 37)
!155 = !DILocation(line: 80, column: 39, scope: !153)
!156 = !DILocation(line: 80, column: 27, scope: !153)
!157 = !DILocation(line: 79, column: 33, scope: !150)
!158 = distinct !{!158, !151, !159, !41}
!159 = !DILocation(line: 83, column: 5, scope: !147)
!160 = !DILocation(line: 84, column: 5, scope: !141)
!161 = distinct !DISubprogram(name: "clamp", scope: !2, file: !2, line: 87, type: !44, scopeLine: 87, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!162 = !DILocalVariable(name: "value", arg: 1, scope: !161, file: !2, line: 87, type: !15)
!163 = !DILocation(line: 0, scope: !161)
!164 = !DILocalVariable(name: "low", scope: !161, file: !2, line: 88, type: !4)
!165 = !DILocalVariable(name: "high", scope: !161, file: !2, line: 89, type: !4)
!166 = !DILocation(line: 90, column: 15, scope: !167)
!167 = distinct !DILexicalBlock(scope: !161, file: !2, line: 90, column: 9)
!168 = !DILocation(line: 97, column: 1, scope: !161)
!169 = distinct !DISubprogram(name: "max_of", scope: !2, file: !2, line: 99, type: !75, scopeLine: 99, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!170 = !DILocalVariable(name: "values", arg: 1, scope: !169, file: !2, line: 99, type: !77)
!171 = !DILocation(line: 0, scope: !169)
!172 = !DILocalVariable(name: "count", arg: 2, scope: !169, file: !2, line: 99, type: !15)
!173 = !DILocation(line: 100, column: 16, scope: !169)
!174 = !DILocalVariable(name: "best", scope: !169, file: !2, line: 100, type: !15)
!175 = !DILocalVariable(name: "i", scope: !176, file: !2, line: 101, type: !15)
!176 = distinct !DILexicalBlock(scope: !169, file: !2, line: 101, column: 5)
!177 = !DILocation(line: 0, scope: !176)
!178 = !DILocation(line: 101, column: 23, scope: !179)
!179 = distinct !DILexicalBlock(scope: !176, file: !2, line: 101, column: 5)
!180 = !DILocation(line: 101, column: 5, scope: !176)
!181 = !DILocation(line: 102, column: 20, scope: !182)
!182 = distinct !DILexicalBlock(scope: !183, file: !2, line: 102, column: 13)
!183 = distinct !DILexicalBlock(scope: !179, file: !2, line: 101, column: 37)
!184 = !DILocation(line: 101, column: 33, scope: !179)
!185 = distinct !{!185, !180, !186, !41}
!186 = !DILocation(line: 105, column: 5, scope: !176)
!187 = !DILocation(line: 106, column: 5, scope: !169)
!188 = distinct !DISubprogram(name: "bump", scope: !2, file: !2, line: 109, type: !44, scopeLine: 109, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!189 = !DILocalVariable(name: "i", arg: 1, scope: !188, file: !2, line: 109, type: !15)
!190 = !DILocation(line: 0, scope: !188)
!191 = !DILocation(line: 110, column: 13, scope: !188)
!192 = !DILocation(line: 111, column: 5, scope: !188)
!193 = distinct !DISubprogram(name: "main", scope: !2, file: !2, line: 114, type: !103, scopeLine: 114, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!194 = !DILocalVariable(name: "values", scope: !193, file: !2, line: 115, type: !195)
!195 = !DICompositeType(tag: DW_TAG_array_type, baseType: !15, size: 192, elements: !196)
!196 = !{!197}
!197 = !DISubrange(count: 6)
!198 = !DILocation(line: 115, column: 9, scope: !193)
!199 = !DILocation(line: 116, column: 17, scope: !193)
!200 = !DILocation(line: 116, column: 5, scope: !193)
!201 = !DILocation(line: 117, column: 12, scope: !193)
!202 = !DILocation(line: 117, column: 40, scope: !193)
!203 = !DILocation(line: 117, column: 38, scope: !193)
!204 = !DILocation(line: 117, column: 60, scope: !193)
!205 = !DILocation(line: 117, column: 58, scope: !193)
!206 = !DILocation(line: 117, column: 90, scope: !193)
!207 = !DILocation(line: 117, column: 84, scope: !193)
!208 = !DILocation(line: 117, column: 82, scope: !193)
!209 = !DILocation(line: 118, column: 11, scope: !193)
!210 = !DILocation(line: 118, column: 9, scope: !193)
!211 = !DILocation(line: 118, column: 34, scope: !193)
!212 = !DILocation(line: 118, column: 32, scope: !193)
!213 = !DILocation(line: 118, column: 47, scope: !193)
!214 = !DILocation(line: 118, column: 45, scope: !193)
!215 = !DILocation(line: 118, column: 71, scope: !193)
!216 = !DILocation(line: 118, column: 66, scope: !193)
!217 = !DILocation(line: 118, column: 64, scope: !193)
!218 = !DILocation(line: 118, column: 87, scope: !193)
!219 = !DILocation(line: 118, column: 85, scope: !193)
!220 = !DILocation(line: 119, column: 11, scope: !193)
!221 = !DILocation(line: 119, column: 9, scope: !193)
!222 = !DILocation(line: 119, column: 30, scope: !193)
!223 = !DILocation(line: 119, column: 28, scope: !193)
!224 = !DILocation(line: 119, column: 47, scope: !193)
!225 = !DILocation(line: 119, column: 45, scope: !193)
!226 = !DILocation(line: 119, column: 65, scope: !193)
!227 = !DILocation(line: 119, column: 63, scope: !193)
!228 = !DILocation(line: 119, column: 86, scope: !193)
!229 = !DILocation(line: 119, column: 84, scope: !193)
!230 = !DILocation(line: 117, column: 5, scope: !193)
