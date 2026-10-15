; ModuleID = '/workspace/out/clang_warnings_08_licm.ll'
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
  br i1 %tobool.not2, label %while.end, label %while.body.lr.ph, !dbg !34

while.body.lr.ph:                                 ; preds = %entry
  br label %while.body, !dbg !34

while.body:                                       ; preds = %while.body, %while.body.lr.ph
  %and5 = phi i32 [ %and1, %while.body.lr.ph ], [ %and, %while.body ]
  %value.addr.04 = phi i32 [ %value, %while.body.lr.ph ], [ %shr, %while.body ]
  %count.03 = phi i32 [ 0, %while.body.lr.ph ], [ %add, %while.body ]
    #dbg_value(i32 %value.addr.04, !30, !DIExpression(), !31)
    #dbg_value(i32 %count.03, !32, !DIExpression(), !31)
  %add = add i32 %count.03, %and5, !dbg !35
    #dbg_value(i32 %add, !32, !DIExpression(), !31)
  %shr = lshr i32 %value.addr.04, 1, !dbg !37
    #dbg_value(i32 %shr, !30, !DIExpression(), !31)
  %and = and i32 %shr, 1, !dbg !33
    #dbg_value(i32 %and, !38, !DIExpression(), !31)
  %tobool.not = icmp eq i32 %and, 0, !dbg !34
  br i1 %tobool.not, label %while.cond.while.end_crit_edge, label %while.body, !dbg !34, !llvm.loop !39

while.cond.while.end_crit_edge:                   ; preds = %while.body
  %split = phi i32 [ %add, %while.body ]
  br label %while.end, !dbg !34

while.end:                                        ; preds = %while.cond.while.end_crit_edge, %entry
  %count.0.lcssa = phi i32 [ %split, %while.cond.while.end_crit_edge ], [ 0, %entry ], !dbg !31
  ret i32 %count.0.lcssa, !dbg !42
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @sum_to(i32 noundef %limit) #0 !dbg !43 {
entry:
    #dbg_value(i32 %limit, !46, !DIExpression(), !47)
    #dbg_value(i32 0, !48, !DIExpression(), !47)
    #dbg_value(i32 0, !49, !DIExpression(), !51)
  %cmp1 = icmp slt i32 0, %limit, !dbg !52
  br i1 %cmp1, label %for.inc.lr.ph, label %for.end, !dbg !54

for.inc.lr.ph:                                    ; preds = %entry
  br label %for.inc, !dbg !54

for.inc:                                          ; preds = %for.inc, %for.inc.lr.ph
  %i.03 = phi i32 [ 0, %for.inc.lr.ph ], [ %inc, %for.inc ]
    #dbg_value(i32 %i.03, !49, !DIExpression(), !51)
    #dbg_value(!DIArgList(i32 poison, i32 %i.03), !48, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_plus, DW_OP_stack_value), !47)
    #dbg_value(!DIArgList(i32 poison, i32 %i.03), !48, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_plus, DW_OP_stack_value), !47)
  %inc = add nuw nsw i32 %i.03, 1, !dbg !55
    #dbg_value(i32 %inc, !49, !DIExpression(), !51)
  br i1 false, label %for.inc, label %for.cond.for.end_crit_edge, !dbg !54, !llvm.loop !56

for.cond.for.end_crit_edge:                       ; preds = %for.inc
  %0 = add i32 %limit, -1, !dbg !54
  %1 = zext i32 %0 to i33, !dbg !54
  %2 = add i32 %limit, -2, !dbg !54
  %3 = zext i32 %2 to i33, !dbg !54
  %4 = mul i33 %1, %3, !dbg !54
  %5 = lshr i33 %4, 1, !dbg !54
  %6 = trunc i33 %5 to i32, !dbg !54
  %7 = add i32 %limit, %6, !dbg !54
  %8 = add i32 %7, -1, !dbg !54
  br label %for.end, !dbg !54

for.end:                                          ; preds = %for.cond.for.end_crit_edge, %entry
  %total.0.lcssa = phi i32 [ %8, %for.cond.for.end_crit_edge ], [ 0, %entry ], !dbg !47
  ret i32 %total.0.lcssa, !dbg !58
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @is_same(i32 noundef %value) #0 !dbg !59 {
entry:
    #dbg_value(i32 %value, !60, !DIExpression(), !61)
  ret i32 1, !dbg !62
}

; Function Attrs: noinline nounwind uwtable
define dso_local zeroext i8 @small_constant() #0 !dbg !63 {
entry:
    #dbg_value(i8 44, !67, !DIExpression(), !68)
  ret i8 44, !dbg !69
}

; Function Attrs: noinline nounwind uwtable
define dso_local i64 @wide_shift(i32 noundef %value) #0 !dbg !70 {
entry:
    #dbg_value(i32 %value, !74, !DIExpression(), !75)
  ret i64 poison, !dbg !76
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @first_positive(ptr noundef %values, i32 noundef %count) #0 !dbg !77 {
entry:
    #dbg_value(ptr %values, !82, !DIExpression(), !83)
    #dbg_value(i32 %count, !84, !DIExpression(), !83)
    #dbg_value(i32 0, !85, !DIExpression(), !87)
  %cmp2 = icmp slt i32 0, %count, !dbg !88
  br i1 %cmp2, label %for.body.lr.ph, label %return, !dbg !90

for.body.lr.ph:                                   ; preds = %entry
  br label %for.body, !dbg !90

for.cond:                                         ; preds = %for.body
    #dbg_value(i32 %inc, !85, !DIExpression(), !87)
  %exitcond = icmp ne i32 %inc, %count, !dbg !88
  br i1 %exitcond, label %for.body, label %for.cond.return_crit_edge, !dbg !90, !llvm.loop !91

for.body:                                         ; preds = %for.cond, %for.body.lr.ph
  %i.03 = phi i32 [ 0, %for.body.lr.ph ], [ %inc, %for.cond ]
    #dbg_value(i32 %i.03, !85, !DIExpression(), !87)
  %idxprom = zext nneg i32 %i.03 to i64, !dbg !93
  %arrayidx = getelementptr inbounds nuw i32, ptr %values, i64 %idxprom, !dbg !93
  %0 = load i32, ptr %arrayidx, align 4, !dbg !93
  %cmp1 = icmp sgt i32 %0, 0, !dbg !96
    #dbg_value(i1 %cmp1, !97, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 32, DW_ATE_unsigned, DW_OP_stack_value), !83)
  %inc = add i32 %i.03, 1, !dbg !98
    #dbg_value(i32 %inc, !85, !DIExpression(), !87)
  br i1 %cmp1, label %for.body.return_crit_edge, label %for.cond, !dbg !99

for.body.return_crit_edge:                        ; preds = %for.body
  %split = phi i32 [ %0, %for.body ]
  br label %return, !dbg !99

for.cond.return_crit_edge:                        ; preds = %for.cond
  %split4 = phi i32 [ 0, %for.cond ]
  br label %return, !dbg !90

return:                                           ; preds = %for.cond.return_crit_edge, %for.body.return_crit_edge, %entry
  %retval.0 = phi i32 [ %split4, %for.cond.return_crit_edge ], [ %split, %for.body.return_crit_edge ], [ 0, %entry ], !dbg !83
  ret i32 %retval.0, !dbg !100
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @skip_empty(i32 noundef %value) #0 !dbg !101 {
entry:
    #dbg_value(i32 %value, !102, !DIExpression(), !103)
  ret i32 %value, !dbg !104
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @truncated_half() #0 !dbg !105 {
entry:
    #dbg_value(i32 2, !107, !DIExpression(), !108)
  ret i32 2, !dbg !109
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @last_of_four() #0 !dbg !110 {
entry:
    #dbg_declare(ptr @__const.last_of_four.four, !111, !DIExpression(), !115)
  ret i32 poison, !dbg !116
}

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @not_equal(i32 noundef %a, i32 noundef %b) #0 !dbg !117 {
entry:
    #dbg_value(i32 %a, !120, !DIExpression(), !121)
    #dbg_value(i32 %b, !122, !DIExpression(), !121)
  %tobool.not = icmp eq i32 %a, 0, !dbg !123
  %lnot.ext = zext i1 %tobool.not to i32, !dbg !123
  %cmp = icmp eq i32 %b, %lnot.ext, !dbg !125
  %. = zext i1 %cmp to i32, !dbg !121
  ret i32 %., !dbg !126
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @array_size(ptr noundef %values) #0 !dbg !127 {
entry:
    #dbg_value(ptr %values, !131, !DIExpression(), !132)
  ret i32 2, !dbg !133
}

; Function Attrs: noinline nounwind uwtable
define dso_local void @print_total(i64 noundef %total, double noundef %mean) #0 !dbg !134 {
entry:
    #dbg_value(i64 %total, !138, !DIExpression(), !139)
    #dbg_value(double %mean, !140, !DIExpression(), !139)
  %call = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i64 noundef %total) #3, !dbg !141
  %call1 = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.1, double noundef %mean) #3, !dbg !142
  ret void, !dbg !143
}

declare i32 @printf(ptr noundef, ...) #2

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @scaled_sum(ptr noundef %values, i32 noundef %count) #0 !dbg !144 {
entry:
    #dbg_value(ptr %values, !145, !DIExpression(), !146)
    #dbg_value(i32 %count, !147, !DIExpression(), !146)
    #dbg_value(i32 0, !148, !DIExpression(), !146)
    #dbg_value(i32 0, !149, !DIExpression(), !151)
  %cmp1 = icmp slt i32 0, %count, !dbg !152
  br i1 %cmp1, label %for.body.lr.ph, label %for.end, !dbg !154

for.body.lr.ph:                                   ; preds = %entry
  %wide.trip.count = zext i32 %count to i64, !dbg !152
  br label %for.body, !dbg !154

for.body:                                         ; preds = %for.body, %for.body.lr.ph
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.body ], [ 0, %for.body.lr.ph ]
  %total.02 = phi i32 [ 0, %for.body.lr.ph ], [ %add, %for.body ]
    #dbg_value(i64 %indvars.iv, !149, !DIExpression(), !151)
    #dbg_value(i32 %total.02, !148, !DIExpression(), !146)
  %arrayidx = getelementptr inbounds nuw i32, ptr %values, i64 %indvars.iv, !dbg !155
  %0 = load i32, ptr %arrayidx, align 4, !dbg !155
  %mul = shl nsw i32 %0, 1, !dbg !158
  %add = add nsw i32 %total.02, %mul, !dbg !159
    #dbg_value(i32 %add, !148, !DIExpression(), !146)
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !160
    #dbg_value(i64 %indvars.iv.next, !149, !DIExpression(), !151)
  %exitcond = icmp ne i64 %indvars.iv.next, %wide.trip.count, !dbg !152
  br i1 %exitcond, label %for.body, label %for.cond.for.end_crit_edge, !dbg !154, !llvm.loop !161

for.cond.for.end_crit_edge:                       ; preds = %for.body
  %split = phi i32 [ %add, %for.body ]
  br label %for.end, !dbg !154

for.end:                                          ; preds = %for.cond.for.end_crit_edge, %entry
  %total.0.lcssa = phi i32 [ %split, %for.cond.for.end_crit_edge ], [ 0, %entry ], !dbg !146
  ret i32 %total.0.lcssa, !dbg !163
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @clamp(i32 noundef %value) #0 !dbg !164 {
entry:
    #dbg_value(i32 %value, !165, !DIExpression(), !166)
    #dbg_value(i8 56, !167, !DIExpression(), !166)
    #dbg_value(i8 -56, !168, !DIExpression(), !166)
  %cmp = icmp slt i32 %value, 56, !dbg !169
  %retval.0 = select i1 %cmp, i32 56, i32 -56, !dbg !169
  ret i32 %retval.0, !dbg !171
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @max_of(ptr noundef %values, i32 noundef %count) #0 !dbg !172 {
entry:
    #dbg_value(ptr %values, !173, !DIExpression(), !174)
    #dbg_value(i32 %count, !175, !DIExpression(), !174)
  %0 = load i32, ptr %values, align 4, !dbg !176
    #dbg_value(i32 %0, !177, !DIExpression(), !174)
    #dbg_value(i32 1, !178, !DIExpression(), !180)
  %cmp1 = icmp slt i32 1, %count, !dbg !181
  br i1 %cmp1, label %for.body.lr.ph, label %for.end, !dbg !183

for.body.lr.ph:                                   ; preds = %entry
  %wide.trip.count = zext i32 %count to i64, !dbg !181
  br label %for.body, !dbg !183

for.body:                                         ; preds = %for.body, %for.body.lr.ph
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.body ], [ 1, %for.body.lr.ph ]
  %best.02 = phi i32 [ %0, %for.body.lr.ph ], [ %spec.select, %for.body ]
    #dbg_value(i64 %indvars.iv, !178, !DIExpression(), !180)
    #dbg_value(i32 %best.02, !177, !DIExpression(), !174)
  %arrayidx1 = getelementptr inbounds nuw i32, ptr %values, i64 %indvars.iv, !dbg !184
  %1 = load i32, ptr %arrayidx1, align 4, !dbg !184
  %cmp2 = icmp sgt i32 %1, %best.02, !dbg !187
  %spec.select = select i1 %cmp2, i32 %1, i32 %best.02, !dbg !184
    #dbg_value(i32 %spec.select, !177, !DIExpression(), !174)
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !188
    #dbg_value(i64 %indvars.iv.next, !178, !DIExpression(), !180)
  %exitcond = icmp ne i64 %indvars.iv.next, %wide.trip.count, !dbg !181
  br i1 %exitcond, label %for.body, label %for.cond.for.end_crit_edge, !dbg !183, !llvm.loop !189

for.cond.for.end_crit_edge:                       ; preds = %for.body
  %split = phi i32 [ %spec.select, %for.body ]
  br label %for.end, !dbg !183

for.end:                                          ; preds = %for.cond.for.end_crit_edge, %entry
  %best.0.lcssa = phi i32 [ %split, %for.cond.for.end_crit_edge ], [ %0, %entry ], !dbg !174
  ret i32 %best.0.lcssa, !dbg !191
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @bump(i32 noundef %i) #0 !dbg !192 {
entry:
    #dbg_value(i32 %i, !193, !DIExpression(), !194)
    #dbg_value(i32 %i, !193, !DIExpression(DW_OP_plus_uconst, 1, DW_OP_stack_value), !194)
    #dbg_value(i32 %i, !193, !DIExpression(DW_OP_plus_uconst, 1, DW_OP_stack_value), !194)
  %add = add nsw i32 %i, 1, !dbg !195
    #dbg_value(i32 %add, !193, !DIExpression(), !194)
  ret i32 %add, !dbg !196
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @main() #0 !dbg !197 {
entry:
  %values = alloca [6 x i32], align 16
    #dbg_declare(ptr %values, !198, !DIExpression(), !202)
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(24) %values, ptr noundef nonnull align 16 dereferenceable(24) @__const.main.values, i64 24, i1 false), !dbg !202
  %call = call i32 @sum_to(i32 noundef 10), !dbg !203
  %conv = sext i32 %call to i64, !dbg !203
  call void @print_total(i64 noundef %conv, double noundef 2.500000e+00), !dbg !204
  %call1 = call i32 @first_positive(ptr noundef nonnull %values, i32 noundef 6), !dbg !205
  %call3 = call i32 @max_of(ptr noundef nonnull %values, i32 noundef 6), !dbg !206
  %add = add nsw i32 %call1, %call3, !dbg !207
  %call5 = call i32 @scaled_sum(ptr noundef nonnull %values, i32 noundef 6), !dbg !208
  %add6 = add nsw i32 %add, %call5, !dbg !209
  %arrayidx = getelementptr inbounds nuw i8, ptr %values, i64 20, !dbg !210
  %0 = load i32, ptr %arrayidx, align 4, !dbg !210
  %call7 = call i32 @clamp(i32 noundef %0), !dbg !211
  %add8 = add nsw i32 %add6, %call7, !dbg !212
  %call9 = call i32 @count_set_bits(i32 noundef 255), !dbg !213
  %add10 = add nsw i32 %add8, %call9, !dbg !214
  %call11 = call i32 @is_same(i32 noundef 1), !dbg !215
  %add12 = add nsw i32 %add10, %call11, !dbg !216
  %call13 = call zeroext i8 @small_constant(), !dbg !217
  %conv14 = zext i8 %call13 to i32, !dbg !217
  %add15 = add nsw i32 %add12, %conv14, !dbg !218
  %call16 = call i64 @wide_shift(i32 noundef 1), !dbg !219
  %conv17 = trunc i64 %call16 to i32, !dbg !220
  %add18 = add nsw i32 %add15, %conv17, !dbg !221
  %call19 = call i32 @skip_empty(i32 noundef 3), !dbg !222
  %add20 = add nsw i32 %add18, %call19, !dbg !223
  %call21 = call i32 @truncated_half(), !dbg !224
  %add22 = add nsw i32 %add20, %call21, !dbg !225
  %call23 = call i32 @last_of_four(), !dbg !226
  %add24 = add nsw i32 %add22, %call23, !dbg !227
  %call25 = call i32 @not_equal(i32 noundef 1, i32 noundef 2), !dbg !228
  %add26 = add nsw i32 %add24, %call25, !dbg !229
  %call28 = call i32 @array_size(ptr noundef nonnull %values), !dbg !230
  %add29 = add nsw i32 %add26, %call28, !dbg !231
  %call30 = call i32 @bump(i32 noundef 2), !dbg !232
  %add31 = add nsw i32 %add29, %call30, !dbg !233
  ret i32 %add31, !dbg !234
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
!55 = !DILocation(line: 16, column: 33, scope: !53)
!56 = distinct !{!56, !54, !57, !41}
!57 = !DILocation(line: 19, column: 5, scope: !50)
!58 = !DILocation(line: 20, column: 5, scope: !43)
!59 = distinct !DISubprogram(name: "is_same", scope: !2, file: !2, line: 23, type: !44, scopeLine: 23, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!60 = !DILocalVariable(name: "value", arg: 1, scope: !59, file: !2, line: 23, type: !15)
!61 = !DILocation(line: 0, scope: !59)
!62 = !DILocation(line: 24, column: 5, scope: !59)
!63 = distinct !DISubprogram(name: "small_constant", scope: !2, file: !2, line: 27, type: !64, scopeLine: 27, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!64 = !DISubroutineType(types: !65)
!65 = !{!66}
!66 = !DIBasicType(name: "unsigned char", size: 8, encoding: DW_ATE_unsigned_char)
!67 = !DILocalVariable(name: "byte", scope: !63, file: !2, line: 28, type: !66)
!68 = !DILocation(line: 0, scope: !63)
!69 = !DILocation(line: 29, column: 5, scope: !63)
!70 = distinct !DISubprogram(name: "wide_shift", scope: !2, file: !2, line: 32, type: !71, scopeLine: 32, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!71 = !DISubroutineType(types: !72)
!72 = !{!73, !15}
!73 = !DIBasicType(name: "long", size: 64, encoding: DW_ATE_signed)
!74 = !DILocalVariable(name: "value", arg: 1, scope: !70, file: !2, line: 32, type: !15)
!75 = !DILocation(line: 0, scope: !70)
!76 = !DILocation(line: 33, column: 5, scope: !70)
!77 = distinct !DISubprogram(name: "first_positive", scope: !2, file: !2, line: 36, type: !78, scopeLine: 36, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!78 = !DISubroutineType(types: !79)
!79 = !{!15, !80, !15}
!80 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !81, size: 64)
!81 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !15)
!82 = !DILocalVariable(name: "values", arg: 1, scope: !77, file: !2, line: 36, type: !80)
!83 = !DILocation(line: 0, scope: !77)
!84 = !DILocalVariable(name: "count", arg: 2, scope: !77, file: !2, line: 36, type: !15)
!85 = !DILocalVariable(name: "i", scope: !86, file: !2, line: 38, type: !15)
!86 = distinct !DILexicalBlock(scope: !77, file: !2, line: 38, column: 5)
!87 = !DILocation(line: 0, scope: !86)
!88 = !DILocation(line: 38, column: 23, scope: !89)
!89 = distinct !DILexicalBlock(scope: !86, file: !2, line: 38, column: 5)
!90 = !DILocation(line: 38, column: 5, scope: !86)
!91 = distinct !{!91, !90, !92, !41}
!92 = !DILocation(line: 42, column: 5, scope: !86)
!93 = !DILocation(line: 39, column: 21, scope: !94)
!94 = distinct !DILexicalBlock(scope: !95, file: !2, line: 39, column: 13)
!95 = distinct !DILexicalBlock(scope: !89, file: !2, line: 38, column: 37)
!96 = !DILocation(line: 39, column: 31, scope: !94)
!97 = !DILocalVariable(name: "found", scope: !77, file: !2, line: 37, type: !15)
!98 = !DILocation(line: 38, column: 33, scope: !89)
!99 = !DILocation(line: 39, column: 19, scope: !94)
!100 = !DILocation(line: 44, column: 1, scope: !77)
!101 = distinct !DISubprogram(name: "skip_empty", scope: !2, file: !2, line: 46, type: !44, scopeLine: 46, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!102 = !DILocalVariable(name: "value", arg: 1, scope: !101, file: !2, line: 46, type: !15)
!103 = !DILocation(line: 0, scope: !101)
!104 = !DILocation(line: 48, column: 5, scope: !101)
!105 = distinct !DISubprogram(name: "truncated_half", scope: !2, file: !2, line: 51, type: !106, scopeLine: 51, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!106 = !DISubroutineType(types: !14)
!107 = !DILocalVariable(name: "half", scope: !105, file: !2, line: 52, type: !15)
!108 = !DILocation(line: 0, scope: !105)
!109 = !DILocation(line: 53, column: 5, scope: !105)
!110 = distinct !DISubprogram(name: "last_of_four", scope: !2, file: !2, line: 56, type: !106, scopeLine: 56, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!111 = !DILocalVariable(name: "four", scope: !110, file: !2, line: 57, type: !112)
!112 = !DICompositeType(tag: DW_TAG_array_type, baseType: !15, size: 128, elements: !113)
!113 = !{!114}
!114 = !DISubrange(count: 4)
!115 = !DILocation(line: 57, column: 9, scope: !110)
!116 = !DILocation(line: 58, column: 5, scope: !110)
!117 = distinct !DISubprogram(name: "not_equal", scope: !2, file: !2, line: 61, type: !118, scopeLine: 61, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!118 = !DISubroutineType(types: !119)
!119 = !{!15, !15, !15}
!120 = !DILocalVariable(name: "a", arg: 1, scope: !117, file: !2, line: 61, type: !15)
!121 = !DILocation(line: 0, scope: !117)
!122 = !DILocalVariable(name: "b", arg: 2, scope: !117, file: !2, line: 61, type: !15)
!123 = !DILocation(line: 62, column: 9, scope: !124)
!124 = distinct !DILexicalBlock(scope: !117, file: !2, line: 62, column: 9)
!125 = !DILocation(line: 62, column: 12, scope: !124)
!126 = !DILocation(line: 66, column: 1, scope: !117)
!127 = distinct !DISubprogram(name: "array_size", scope: !2, file: !2, line: 68, type: !128, scopeLine: 68, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!128 = !DISubroutineType(types: !129)
!129 = !{!15, !130}
!130 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !15, size: 64)
!131 = !DILocalVariable(name: "values", arg: 1, scope: !127, file: !2, line: 68, type: !130)
!132 = !DILocation(line: 0, scope: !127)
!133 = !DILocation(line: 69, column: 5, scope: !127)
!134 = distinct !DISubprogram(name: "print_total", scope: !2, file: !2, line: 72, type: !135, scopeLine: 72, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!135 = !DISubroutineType(types: !136)
!136 = !{null, !73, !137}
!137 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!138 = !DILocalVariable(name: "total", arg: 1, scope: !134, file: !2, line: 72, type: !73)
!139 = !DILocation(line: 0, scope: !134)
!140 = !DILocalVariable(name: "mean", arg: 2, scope: !134, file: !2, line: 72, type: !137)
!141 = !DILocation(line: 73, column: 5, scope: !134)
!142 = !DILocation(line: 74, column: 5, scope: !134)
!143 = !DILocation(line: 75, column: 1, scope: !134)
!144 = distinct !DISubprogram(name: "scaled_sum", scope: !2, file: !2, line: 77, type: !78, scopeLine: 77, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!145 = !DILocalVariable(name: "values", arg: 1, scope: !144, file: !2, line: 77, type: !80)
!146 = !DILocation(line: 0, scope: !144)
!147 = !DILocalVariable(name: "count", arg: 2, scope: !144, file: !2, line: 77, type: !15)
!148 = !DILocalVariable(name: "total", scope: !144, file: !2, line: 78, type: !15)
!149 = !DILocalVariable(name: "i", scope: !150, file: !2, line: 79, type: !15)
!150 = distinct !DILexicalBlock(scope: !144, file: !2, line: 79, column: 5)
!151 = !DILocation(line: 0, scope: !150)
!152 = !DILocation(line: 79, column: 23, scope: !153)
!153 = distinct !DILexicalBlock(scope: !150, file: !2, line: 79, column: 5)
!154 = !DILocation(line: 79, column: 5, scope: !150)
!155 = !DILocation(line: 80, column: 29, scope: !156)
!156 = distinct !DILexicalBlock(scope: !157, file: !2, line: 80, column: 13)
!157 = distinct !DILexicalBlock(scope: !153, file: !2, line: 79, column: 37)
!158 = !DILocation(line: 80, column: 39, scope: !156)
!159 = !DILocation(line: 80, column: 27, scope: !156)
!160 = !DILocation(line: 79, column: 33, scope: !153)
!161 = distinct !{!161, !154, !162, !41}
!162 = !DILocation(line: 83, column: 5, scope: !150)
!163 = !DILocation(line: 84, column: 5, scope: !144)
!164 = distinct !DISubprogram(name: "clamp", scope: !2, file: !2, line: 87, type: !44, scopeLine: 87, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!165 = !DILocalVariable(name: "value", arg: 1, scope: !164, file: !2, line: 87, type: !15)
!166 = !DILocation(line: 0, scope: !164)
!167 = !DILocalVariable(name: "low", scope: !164, file: !2, line: 88, type: !4)
!168 = !DILocalVariable(name: "high", scope: !164, file: !2, line: 89, type: !4)
!169 = !DILocation(line: 90, column: 15, scope: !170)
!170 = distinct !DILexicalBlock(scope: !164, file: !2, line: 90, column: 9)
!171 = !DILocation(line: 97, column: 1, scope: !164)
!172 = distinct !DISubprogram(name: "max_of", scope: !2, file: !2, line: 99, type: !78, scopeLine: 99, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!173 = !DILocalVariable(name: "values", arg: 1, scope: !172, file: !2, line: 99, type: !80)
!174 = !DILocation(line: 0, scope: !172)
!175 = !DILocalVariable(name: "count", arg: 2, scope: !172, file: !2, line: 99, type: !15)
!176 = !DILocation(line: 100, column: 16, scope: !172)
!177 = !DILocalVariable(name: "best", scope: !172, file: !2, line: 100, type: !15)
!178 = !DILocalVariable(name: "i", scope: !179, file: !2, line: 101, type: !15)
!179 = distinct !DILexicalBlock(scope: !172, file: !2, line: 101, column: 5)
!180 = !DILocation(line: 0, scope: !179)
!181 = !DILocation(line: 101, column: 23, scope: !182)
!182 = distinct !DILexicalBlock(scope: !179, file: !2, line: 101, column: 5)
!183 = !DILocation(line: 101, column: 5, scope: !179)
!184 = !DILocation(line: 102, column: 20, scope: !185)
!185 = distinct !DILexicalBlock(scope: !186, file: !2, line: 102, column: 13)
!186 = distinct !DILexicalBlock(scope: !182, file: !2, line: 101, column: 37)
!187 = !DILocation(line: 102, column: 30, scope: !185)
!188 = !DILocation(line: 101, column: 33, scope: !182)
!189 = distinct !{!189, !183, !190, !41}
!190 = !DILocation(line: 105, column: 5, scope: !179)
!191 = !DILocation(line: 106, column: 5, scope: !172)
!192 = distinct !DISubprogram(name: "bump", scope: !2, file: !2, line: 109, type: !44, scopeLine: 109, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!193 = !DILocalVariable(name: "i", arg: 1, scope: !192, file: !2, line: 109, type: !15)
!194 = !DILocation(line: 0, scope: !192)
!195 = !DILocation(line: 110, column: 13, scope: !192)
!196 = !DILocation(line: 111, column: 5, scope: !192)
!197 = distinct !DISubprogram(name: "main", scope: !2, file: !2, line: 114, type: !106, scopeLine: 114, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!198 = !DILocalVariable(name: "values", scope: !197, file: !2, line: 115, type: !199)
!199 = !DICompositeType(tag: DW_TAG_array_type, baseType: !15, size: 192, elements: !200)
!200 = !{!201}
!201 = !DISubrange(count: 6)
!202 = !DILocation(line: 115, column: 9, scope: !197)
!203 = !DILocation(line: 116, column: 17, scope: !197)
!204 = !DILocation(line: 116, column: 5, scope: !197)
!205 = !DILocation(line: 117, column: 12, scope: !197)
!206 = !DILocation(line: 117, column: 40, scope: !197)
!207 = !DILocation(line: 117, column: 38, scope: !197)
!208 = !DILocation(line: 117, column: 60, scope: !197)
!209 = !DILocation(line: 117, column: 58, scope: !197)
!210 = !DILocation(line: 117, column: 90, scope: !197)
!211 = !DILocation(line: 117, column: 84, scope: !197)
!212 = !DILocation(line: 117, column: 82, scope: !197)
!213 = !DILocation(line: 118, column: 11, scope: !197)
!214 = !DILocation(line: 118, column: 9, scope: !197)
!215 = !DILocation(line: 118, column: 34, scope: !197)
!216 = !DILocation(line: 118, column: 32, scope: !197)
!217 = !DILocation(line: 118, column: 47, scope: !197)
!218 = !DILocation(line: 118, column: 45, scope: !197)
!219 = !DILocation(line: 118, column: 71, scope: !197)
!220 = !DILocation(line: 118, column: 66, scope: !197)
!221 = !DILocation(line: 118, column: 64, scope: !197)
!222 = !DILocation(line: 118, column: 87, scope: !197)
!223 = !DILocation(line: 118, column: 85, scope: !197)
!224 = !DILocation(line: 119, column: 11, scope: !197)
!225 = !DILocation(line: 119, column: 9, scope: !197)
!226 = !DILocation(line: 119, column: 30, scope: !197)
!227 = !DILocation(line: 119, column: 28, scope: !197)
!228 = !DILocation(line: 119, column: 47, scope: !197)
!229 = !DILocation(line: 119, column: 45, scope: !197)
!230 = !DILocation(line: 119, column: 65, scope: !197)
!231 = !DILocation(line: 119, column: 63, scope: !197)
!232 = !DILocation(line: 119, column: 86, scope: !197)
!233 = !DILocation(line: 119, column: 84, scope: !197)
!234 = !DILocation(line: 117, column: 5, scope: !197)
