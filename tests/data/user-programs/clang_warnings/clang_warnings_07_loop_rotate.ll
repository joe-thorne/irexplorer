; ModuleID = '/workspace/out/clang_warnings_06_loop_canonical.ll'
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

while.body:                                       ; preds = %while.body.lr.ph, %while.body
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

for.inc:                                          ; preds = %for.inc.lr.ph, %for.inc
  %i.03 = phi i32 [ 0, %for.inc.lr.ph ], [ %inc, %for.inc ]
  %total.02 = phi i32 [ 0, %for.inc.lr.ph ], [ %add1, %for.inc ]
    #dbg_value(i32 %i.03, !49, !DIExpression(), !51)
    #dbg_value(!DIArgList(i32 %total.02, i32 %i.03), !48, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_plus, DW_OP_stack_value), !47)
  %add1 = add nuw nsw i32 %total.02, %i.03, !dbg !55
    #dbg_value(i32 %add1, !48, !DIExpression(), !47)
  %inc = add nuw nsw i32 %i.03, 1, !dbg !57
    #dbg_value(i32 %inc, !49, !DIExpression(), !51)
  %cmp = icmp slt i32 %inc, %limit, !dbg !52
  br i1 %cmp, label %for.inc, label %for.cond.for.end_crit_edge, !dbg !54, !llvm.loop !58

for.cond.for.end_crit_edge:                       ; preds = %for.inc
  %split = phi i32 [ %add1, %for.inc ]
  br label %for.end, !dbg !54

for.end:                                          ; preds = %for.cond.for.end_crit_edge, %entry
  %total.0.lcssa = phi i32 [ %split, %for.cond.for.end_crit_edge ], [ 0, %entry ], !dbg !47
  ret i32 %total.0.lcssa, !dbg !60
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @is_same(i32 noundef %value) #0 !dbg !61 {
entry:
    #dbg_value(i32 %value, !62, !DIExpression(), !63)
  ret i32 1, !dbg !64
}

; Function Attrs: noinline nounwind uwtable
define dso_local zeroext i8 @small_constant() #0 !dbg !65 {
entry:
    #dbg_value(i8 44, !69, !DIExpression(), !70)
  ret i8 44, !dbg !71
}

; Function Attrs: noinline nounwind uwtable
define dso_local i64 @wide_shift(i32 noundef %value) #0 !dbg !72 {
entry:
    #dbg_value(i32 %value, !76, !DIExpression(), !77)
  ret i64 poison, !dbg !78
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @first_positive(ptr noundef %values, i32 noundef %count) #0 !dbg !79 {
entry:
    #dbg_value(ptr %values, !84, !DIExpression(), !85)
    #dbg_value(i32 %count, !86, !DIExpression(), !85)
    #dbg_value(i32 0, !87, !DIExpression(), !89)
  %cmp2 = icmp slt i32 0, %count, !dbg !90
  br i1 %cmp2, label %for.body.lr.ph, label %return, !dbg !92

for.body.lr.ph:                                   ; preds = %entry
  br label %for.body, !dbg !92

for.cond:                                         ; preds = %for.body
  %i.0 = phi i32 [ %inc, %for.body ], !dbg !93
    #dbg_value(i32 %i.0, !87, !DIExpression(), !89)
  %cmp = icmp slt i32 %i.0, %count, !dbg !90
  br i1 %cmp, label %for.body, label %for.cond.return_crit_edge, !dbg !92, !llvm.loop !94

for.body:                                         ; preds = %for.body.lr.ph, %for.cond
  %i.03 = phi i32 [ 0, %for.body.lr.ph ], [ %i.0, %for.cond ]
    #dbg_value(i32 %i.03, !87, !DIExpression(), !89)
  %idxprom = zext nneg i32 %i.03 to i64, !dbg !96
  %arrayidx = getelementptr inbounds nuw i32, ptr %values, i64 %idxprom, !dbg !96
  %0 = load i32, ptr %arrayidx, align 4, !dbg !96
  %cmp1 = icmp sgt i32 %0, 0, !dbg !99
    #dbg_value(i1 %cmp1, !100, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 32, DW_ATE_unsigned, DW_OP_stack_value), !85)
  %inc = add nuw nsw i32 %i.03, 1, !dbg !101
    #dbg_value(i32 %inc, !87, !DIExpression(), !89)
  br i1 %cmp1, label %for.body.return_crit_edge, label %for.cond, !dbg !102

for.body.return_crit_edge:                        ; preds = %for.body
  %split = phi i32 [ %0, %for.body ]
  br label %return, !dbg !102

for.cond.return_crit_edge:                        ; preds = %for.cond
  %split4 = phi i32 [ 0, %for.cond ]
  br label %return, !dbg !92

return:                                           ; preds = %for.cond.return_crit_edge, %for.body.return_crit_edge, %entry
  %retval.0 = phi i32 [ %split4, %for.cond.return_crit_edge ], [ %split, %for.body.return_crit_edge ], [ 0, %entry ], !dbg !85
  ret i32 %retval.0, !dbg !103
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @skip_empty(i32 noundef %value) #0 !dbg !104 {
entry:
    #dbg_value(i32 %value, !105, !DIExpression(), !106)
  ret i32 %value, !dbg !107
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @truncated_half() #0 !dbg !108 {
entry:
    #dbg_value(i32 2, !110, !DIExpression(), !111)
  ret i32 2, !dbg !112
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @last_of_four() #0 !dbg !113 {
entry:
    #dbg_declare(ptr @__const.last_of_four.four, !114, !DIExpression(), !118)
  ret i32 poison, !dbg !119
}

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @not_equal(i32 noundef %a, i32 noundef %b) #0 !dbg !120 {
entry:
    #dbg_value(i32 %a, !123, !DIExpression(), !124)
    #dbg_value(i32 %b, !125, !DIExpression(), !124)
  %tobool.not = icmp eq i32 %a, 0, !dbg !126
  %lnot.ext = zext i1 %tobool.not to i32, !dbg !126
  %cmp = icmp eq i32 %b, %lnot.ext, !dbg !128
  %. = zext i1 %cmp to i32, !dbg !124
  ret i32 %., !dbg !129
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @array_size(ptr noundef %values) #0 !dbg !130 {
entry:
    #dbg_value(ptr %values, !134, !DIExpression(), !135)
  ret i32 2, !dbg !136
}

; Function Attrs: noinline nounwind uwtable
define dso_local void @print_total(i64 noundef %total, double noundef %mean) #0 !dbg !137 {
entry:
    #dbg_value(i64 %total, !141, !DIExpression(), !142)
    #dbg_value(double %mean, !143, !DIExpression(), !142)
  %call = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i64 noundef %total) #3, !dbg !144
  %call1 = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.1, double noundef %mean) #3, !dbg !145
  ret void, !dbg !146
}

declare i32 @printf(ptr noundef, ...) #2

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @scaled_sum(ptr noundef %values, i32 noundef %count) #0 !dbg !147 {
entry:
    #dbg_value(ptr %values, !148, !DIExpression(), !149)
    #dbg_value(i32 %count, !150, !DIExpression(), !149)
    #dbg_value(i32 0, !151, !DIExpression(), !149)
    #dbg_value(i32 0, !152, !DIExpression(), !154)
  %cmp1 = icmp slt i32 0, %count, !dbg !155
  br i1 %cmp1, label %for.body.lr.ph, label %for.end, !dbg !157

for.body.lr.ph:                                   ; preds = %entry
  br label %for.body, !dbg !157

for.body:                                         ; preds = %for.body.lr.ph, %for.body
  %i.03 = phi i32 [ 0, %for.body.lr.ph ], [ %inc, %for.body ]
  %total.02 = phi i32 [ 0, %for.body.lr.ph ], [ %add, %for.body ]
    #dbg_value(i32 %i.03, !152, !DIExpression(), !154)
    #dbg_value(i32 %total.02, !151, !DIExpression(), !149)
  %idxprom = zext nneg i32 %i.03 to i64, !dbg !158
  %arrayidx = getelementptr inbounds nuw i32, ptr %values, i64 %idxprom, !dbg !158
  %0 = load i32, ptr %arrayidx, align 4, !dbg !158
  %mul = shl nsw i32 %0, 1, !dbg !161
  %add = add nsw i32 %total.02, %mul, !dbg !162
    #dbg_value(i32 %add, !151, !DIExpression(), !149)
  %inc = add nuw nsw i32 %i.03, 1, !dbg !163
    #dbg_value(i32 %inc, !152, !DIExpression(), !154)
  %cmp = icmp slt i32 %inc, %count, !dbg !155
  br i1 %cmp, label %for.body, label %for.cond.for.end_crit_edge, !dbg !157, !llvm.loop !164

for.cond.for.end_crit_edge:                       ; preds = %for.body
  %split = phi i32 [ %add, %for.body ]
  br label %for.end, !dbg !157

for.end:                                          ; preds = %for.cond.for.end_crit_edge, %entry
  %total.0.lcssa = phi i32 [ %split, %for.cond.for.end_crit_edge ], [ 0, %entry ], !dbg !149
  ret i32 %total.0.lcssa, !dbg !166
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @clamp(i32 noundef %value) #0 !dbg !167 {
entry:
    #dbg_value(i32 %value, !168, !DIExpression(), !169)
    #dbg_value(i8 56, !170, !DIExpression(), !169)
    #dbg_value(i8 -56, !171, !DIExpression(), !169)
  %cmp = icmp slt i32 %value, 56, !dbg !172
  %retval.0 = select i1 %cmp, i32 56, i32 -56, !dbg !172
  ret i32 %retval.0, !dbg !174
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @max_of(ptr noundef %values, i32 noundef %count) #0 !dbg !175 {
entry:
    #dbg_value(ptr %values, !176, !DIExpression(), !177)
    #dbg_value(i32 %count, !178, !DIExpression(), !177)
  %0 = load i32, ptr %values, align 4, !dbg !179
    #dbg_value(i32 %0, !180, !DIExpression(), !177)
    #dbg_value(i32 1, !181, !DIExpression(), !183)
  %cmp1 = icmp slt i32 1, %count, !dbg !184
  br i1 %cmp1, label %for.body.lr.ph, label %for.end, !dbg !186

for.body.lr.ph:                                   ; preds = %entry
  br label %for.body, !dbg !186

for.body:                                         ; preds = %for.body.lr.ph, %for.body
  %i.03 = phi i32 [ 1, %for.body.lr.ph ], [ %inc, %for.body ]
  %best.02 = phi i32 [ %0, %for.body.lr.ph ], [ %spec.select, %for.body ]
    #dbg_value(i32 %i.03, !181, !DIExpression(), !183)
    #dbg_value(i32 %best.02, !180, !DIExpression(), !177)
  %idxprom = zext nneg i32 %i.03 to i64, !dbg !187
  %arrayidx1 = getelementptr inbounds nuw i32, ptr %values, i64 %idxprom, !dbg !187
  %1 = load i32, ptr %arrayidx1, align 4, !dbg !187
  %cmp2 = icmp sgt i32 %1, %best.02, !dbg !190
  %spec.select = select i1 %cmp2, i32 %1, i32 %best.02, !dbg !187
    #dbg_value(i32 %spec.select, !180, !DIExpression(), !177)
  %inc = add nuw nsw i32 %i.03, 1, !dbg !191
    #dbg_value(i32 %inc, !181, !DIExpression(), !183)
  %cmp = icmp slt i32 %inc, %count, !dbg !184
  br i1 %cmp, label %for.body, label %for.cond.for.end_crit_edge, !dbg !186, !llvm.loop !192

for.cond.for.end_crit_edge:                       ; preds = %for.body
  %split = phi i32 [ %spec.select, %for.body ]
  br label %for.end, !dbg !186

for.end:                                          ; preds = %for.cond.for.end_crit_edge, %entry
  %best.0.lcssa = phi i32 [ %split, %for.cond.for.end_crit_edge ], [ %0, %entry ], !dbg !177
  ret i32 %best.0.lcssa, !dbg !194
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @bump(i32 noundef %i) #0 !dbg !195 {
entry:
    #dbg_value(i32 %i, !196, !DIExpression(), !197)
    #dbg_value(i32 %i, !196, !DIExpression(DW_OP_plus_uconst, 1, DW_OP_stack_value), !197)
    #dbg_value(i32 %i, !196, !DIExpression(DW_OP_plus_uconst, 1, DW_OP_stack_value), !197)
  %add = add nsw i32 %i, 1, !dbg !198
    #dbg_value(i32 %add, !196, !DIExpression(), !197)
  ret i32 %add, !dbg !199
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @main() #0 !dbg !200 {
entry:
  %values = alloca [6 x i32], align 16
    #dbg_declare(ptr %values, !201, !DIExpression(), !205)
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(24) %values, ptr noundef nonnull align 16 dereferenceable(24) @__const.main.values, i64 24, i1 false), !dbg !205
  %call = call i32 @sum_to(i32 noundef 10), !dbg !206
  %conv = sext i32 %call to i64, !dbg !206
  call void @print_total(i64 noundef %conv, double noundef 2.500000e+00), !dbg !207
  %call1 = call i32 @first_positive(ptr noundef nonnull %values, i32 noundef 6), !dbg !208
  %call3 = call i32 @max_of(ptr noundef nonnull %values, i32 noundef 6), !dbg !209
  %add = add nsw i32 %call1, %call3, !dbg !210
  %call5 = call i32 @scaled_sum(ptr noundef nonnull %values, i32 noundef 6), !dbg !211
  %add6 = add nsw i32 %add, %call5, !dbg !212
  %arrayidx = getelementptr inbounds nuw i8, ptr %values, i64 20, !dbg !213
  %0 = load i32, ptr %arrayidx, align 4, !dbg !213
  %call7 = call i32 @clamp(i32 noundef %0), !dbg !214
  %add8 = add nsw i32 %add6, %call7, !dbg !215
  %call9 = call i32 @count_set_bits(i32 noundef 255), !dbg !216
  %add10 = add nsw i32 %add8, %call9, !dbg !217
  %call11 = call i32 @is_same(i32 noundef 1), !dbg !218
  %add12 = add nsw i32 %add10, %call11, !dbg !219
  %call13 = call zeroext i8 @small_constant(), !dbg !220
  %conv14 = zext i8 %call13 to i32, !dbg !220
  %add15 = add nsw i32 %add12, %conv14, !dbg !221
  %call16 = call i64 @wide_shift(i32 noundef 1), !dbg !222
  %conv17 = trunc i64 %call16 to i32, !dbg !223
  %add18 = add nsw i32 %add15, %conv17, !dbg !224
  %call19 = call i32 @skip_empty(i32 noundef 3), !dbg !225
  %add20 = add nsw i32 %add18, %call19, !dbg !226
  %call21 = call i32 @truncated_half(), !dbg !227
  %add22 = add nsw i32 %add20, %call21, !dbg !228
  %call23 = call i32 @last_of_four(), !dbg !229
  %add24 = add nsw i32 %add22, %call23, !dbg !230
  %call25 = call i32 @not_equal(i32 noundef 1, i32 noundef 2), !dbg !231
  %add26 = add nsw i32 %add24, %call25, !dbg !232
  %call28 = call i32 @array_size(ptr noundef nonnull %values), !dbg !233
  %add29 = add nsw i32 %add26, %call28, !dbg !234
  %call30 = call i32 @bump(i32 noundef 2), !dbg !235
  %add31 = add nsw i32 %add29, %call30, !dbg !236
  ret i32 %add31, !dbg !237
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
!55 = !DILocation(line: 18, column: 15, scope: !56)
!56 = distinct !DILexicalBlock(scope: !53, file: !2, line: 16, column: 37)
!57 = !DILocation(line: 16, column: 33, scope: !53)
!58 = distinct !{!58, !54, !59, !41}
!59 = !DILocation(line: 19, column: 5, scope: !50)
!60 = !DILocation(line: 20, column: 5, scope: !43)
!61 = distinct !DISubprogram(name: "is_same", scope: !2, file: !2, line: 23, type: !44, scopeLine: 23, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!62 = !DILocalVariable(name: "value", arg: 1, scope: !61, file: !2, line: 23, type: !15)
!63 = !DILocation(line: 0, scope: !61)
!64 = !DILocation(line: 24, column: 5, scope: !61)
!65 = distinct !DISubprogram(name: "small_constant", scope: !2, file: !2, line: 27, type: !66, scopeLine: 27, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!66 = !DISubroutineType(types: !67)
!67 = !{!68}
!68 = !DIBasicType(name: "unsigned char", size: 8, encoding: DW_ATE_unsigned_char)
!69 = !DILocalVariable(name: "byte", scope: !65, file: !2, line: 28, type: !68)
!70 = !DILocation(line: 0, scope: !65)
!71 = !DILocation(line: 29, column: 5, scope: !65)
!72 = distinct !DISubprogram(name: "wide_shift", scope: !2, file: !2, line: 32, type: !73, scopeLine: 32, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!73 = !DISubroutineType(types: !74)
!74 = !{!75, !15}
!75 = !DIBasicType(name: "long", size: 64, encoding: DW_ATE_signed)
!76 = !DILocalVariable(name: "value", arg: 1, scope: !72, file: !2, line: 32, type: !15)
!77 = !DILocation(line: 0, scope: !72)
!78 = !DILocation(line: 33, column: 5, scope: !72)
!79 = distinct !DISubprogram(name: "first_positive", scope: !2, file: !2, line: 36, type: !80, scopeLine: 36, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!80 = !DISubroutineType(types: !81)
!81 = !{!15, !82, !15}
!82 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !83, size: 64)
!83 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !15)
!84 = !DILocalVariable(name: "values", arg: 1, scope: !79, file: !2, line: 36, type: !82)
!85 = !DILocation(line: 0, scope: !79)
!86 = !DILocalVariable(name: "count", arg: 2, scope: !79, file: !2, line: 36, type: !15)
!87 = !DILocalVariable(name: "i", scope: !88, file: !2, line: 38, type: !15)
!88 = distinct !DILexicalBlock(scope: !79, file: !2, line: 38, column: 5)
!89 = !DILocation(line: 0, scope: !88)
!90 = !DILocation(line: 38, column: 23, scope: !91)
!91 = distinct !DILexicalBlock(scope: !88, file: !2, line: 38, column: 5)
!92 = !DILocation(line: 38, column: 5, scope: !88)
!93 = !DILocation(line: 38, scope: !88)
!94 = distinct !{!94, !92, !95, !41}
!95 = !DILocation(line: 42, column: 5, scope: !88)
!96 = !DILocation(line: 39, column: 21, scope: !97)
!97 = distinct !DILexicalBlock(scope: !98, file: !2, line: 39, column: 13)
!98 = distinct !DILexicalBlock(scope: !91, file: !2, line: 38, column: 37)
!99 = !DILocation(line: 39, column: 31, scope: !97)
!100 = !DILocalVariable(name: "found", scope: !79, file: !2, line: 37, type: !15)
!101 = !DILocation(line: 38, column: 33, scope: !91)
!102 = !DILocation(line: 39, column: 19, scope: !97)
!103 = !DILocation(line: 44, column: 1, scope: !79)
!104 = distinct !DISubprogram(name: "skip_empty", scope: !2, file: !2, line: 46, type: !44, scopeLine: 46, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!105 = !DILocalVariable(name: "value", arg: 1, scope: !104, file: !2, line: 46, type: !15)
!106 = !DILocation(line: 0, scope: !104)
!107 = !DILocation(line: 48, column: 5, scope: !104)
!108 = distinct !DISubprogram(name: "truncated_half", scope: !2, file: !2, line: 51, type: !109, scopeLine: 51, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!109 = !DISubroutineType(types: !14)
!110 = !DILocalVariable(name: "half", scope: !108, file: !2, line: 52, type: !15)
!111 = !DILocation(line: 0, scope: !108)
!112 = !DILocation(line: 53, column: 5, scope: !108)
!113 = distinct !DISubprogram(name: "last_of_four", scope: !2, file: !2, line: 56, type: !109, scopeLine: 56, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!114 = !DILocalVariable(name: "four", scope: !113, file: !2, line: 57, type: !115)
!115 = !DICompositeType(tag: DW_TAG_array_type, baseType: !15, size: 128, elements: !116)
!116 = !{!117}
!117 = !DISubrange(count: 4)
!118 = !DILocation(line: 57, column: 9, scope: !113)
!119 = !DILocation(line: 58, column: 5, scope: !113)
!120 = distinct !DISubprogram(name: "not_equal", scope: !2, file: !2, line: 61, type: !121, scopeLine: 61, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!121 = !DISubroutineType(types: !122)
!122 = !{!15, !15, !15}
!123 = !DILocalVariable(name: "a", arg: 1, scope: !120, file: !2, line: 61, type: !15)
!124 = !DILocation(line: 0, scope: !120)
!125 = !DILocalVariable(name: "b", arg: 2, scope: !120, file: !2, line: 61, type: !15)
!126 = !DILocation(line: 62, column: 9, scope: !127)
!127 = distinct !DILexicalBlock(scope: !120, file: !2, line: 62, column: 9)
!128 = !DILocation(line: 62, column: 12, scope: !127)
!129 = !DILocation(line: 66, column: 1, scope: !120)
!130 = distinct !DISubprogram(name: "array_size", scope: !2, file: !2, line: 68, type: !131, scopeLine: 68, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!131 = !DISubroutineType(types: !132)
!132 = !{!15, !133}
!133 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !15, size: 64)
!134 = !DILocalVariable(name: "values", arg: 1, scope: !130, file: !2, line: 68, type: !133)
!135 = !DILocation(line: 0, scope: !130)
!136 = !DILocation(line: 69, column: 5, scope: !130)
!137 = distinct !DISubprogram(name: "print_total", scope: !2, file: !2, line: 72, type: !138, scopeLine: 72, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!138 = !DISubroutineType(types: !139)
!139 = !{null, !75, !140}
!140 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!141 = !DILocalVariable(name: "total", arg: 1, scope: !137, file: !2, line: 72, type: !75)
!142 = !DILocation(line: 0, scope: !137)
!143 = !DILocalVariable(name: "mean", arg: 2, scope: !137, file: !2, line: 72, type: !140)
!144 = !DILocation(line: 73, column: 5, scope: !137)
!145 = !DILocation(line: 74, column: 5, scope: !137)
!146 = !DILocation(line: 75, column: 1, scope: !137)
!147 = distinct !DISubprogram(name: "scaled_sum", scope: !2, file: !2, line: 77, type: !80, scopeLine: 77, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!148 = !DILocalVariable(name: "values", arg: 1, scope: !147, file: !2, line: 77, type: !82)
!149 = !DILocation(line: 0, scope: !147)
!150 = !DILocalVariable(name: "count", arg: 2, scope: !147, file: !2, line: 77, type: !15)
!151 = !DILocalVariable(name: "total", scope: !147, file: !2, line: 78, type: !15)
!152 = !DILocalVariable(name: "i", scope: !153, file: !2, line: 79, type: !15)
!153 = distinct !DILexicalBlock(scope: !147, file: !2, line: 79, column: 5)
!154 = !DILocation(line: 0, scope: !153)
!155 = !DILocation(line: 79, column: 23, scope: !156)
!156 = distinct !DILexicalBlock(scope: !153, file: !2, line: 79, column: 5)
!157 = !DILocation(line: 79, column: 5, scope: !153)
!158 = !DILocation(line: 80, column: 29, scope: !159)
!159 = distinct !DILexicalBlock(scope: !160, file: !2, line: 80, column: 13)
!160 = distinct !DILexicalBlock(scope: !156, file: !2, line: 79, column: 37)
!161 = !DILocation(line: 80, column: 39, scope: !159)
!162 = !DILocation(line: 80, column: 27, scope: !159)
!163 = !DILocation(line: 79, column: 33, scope: !156)
!164 = distinct !{!164, !157, !165, !41}
!165 = !DILocation(line: 83, column: 5, scope: !153)
!166 = !DILocation(line: 84, column: 5, scope: !147)
!167 = distinct !DISubprogram(name: "clamp", scope: !2, file: !2, line: 87, type: !44, scopeLine: 87, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!168 = !DILocalVariable(name: "value", arg: 1, scope: !167, file: !2, line: 87, type: !15)
!169 = !DILocation(line: 0, scope: !167)
!170 = !DILocalVariable(name: "low", scope: !167, file: !2, line: 88, type: !4)
!171 = !DILocalVariable(name: "high", scope: !167, file: !2, line: 89, type: !4)
!172 = !DILocation(line: 90, column: 15, scope: !173)
!173 = distinct !DILexicalBlock(scope: !167, file: !2, line: 90, column: 9)
!174 = !DILocation(line: 97, column: 1, scope: !167)
!175 = distinct !DISubprogram(name: "max_of", scope: !2, file: !2, line: 99, type: !80, scopeLine: 99, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!176 = !DILocalVariable(name: "values", arg: 1, scope: !175, file: !2, line: 99, type: !82)
!177 = !DILocation(line: 0, scope: !175)
!178 = !DILocalVariable(name: "count", arg: 2, scope: !175, file: !2, line: 99, type: !15)
!179 = !DILocation(line: 100, column: 16, scope: !175)
!180 = !DILocalVariable(name: "best", scope: !175, file: !2, line: 100, type: !15)
!181 = !DILocalVariable(name: "i", scope: !182, file: !2, line: 101, type: !15)
!182 = distinct !DILexicalBlock(scope: !175, file: !2, line: 101, column: 5)
!183 = !DILocation(line: 0, scope: !182)
!184 = !DILocation(line: 101, column: 23, scope: !185)
!185 = distinct !DILexicalBlock(scope: !182, file: !2, line: 101, column: 5)
!186 = !DILocation(line: 101, column: 5, scope: !182)
!187 = !DILocation(line: 102, column: 20, scope: !188)
!188 = distinct !DILexicalBlock(scope: !189, file: !2, line: 102, column: 13)
!189 = distinct !DILexicalBlock(scope: !185, file: !2, line: 101, column: 37)
!190 = !DILocation(line: 102, column: 30, scope: !188)
!191 = !DILocation(line: 101, column: 33, scope: !185)
!192 = distinct !{!192, !186, !193, !41}
!193 = !DILocation(line: 105, column: 5, scope: !182)
!194 = !DILocation(line: 106, column: 5, scope: !175)
!195 = distinct !DISubprogram(name: "bump", scope: !2, file: !2, line: 109, type: !44, scopeLine: 109, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!196 = !DILocalVariable(name: "i", arg: 1, scope: !195, file: !2, line: 109, type: !15)
!197 = !DILocation(line: 0, scope: !195)
!198 = !DILocation(line: 110, column: 13, scope: !195)
!199 = !DILocation(line: 111, column: 5, scope: !195)
!200 = distinct !DISubprogram(name: "main", scope: !2, file: !2, line: 114, type: !109, scopeLine: 114, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!201 = !DILocalVariable(name: "values", scope: !200, file: !2, line: 115, type: !202)
!202 = !DICompositeType(tag: DW_TAG_array_type, baseType: !15, size: 192, elements: !203)
!203 = !{!204}
!204 = !DISubrange(count: 6)
!205 = !DILocation(line: 115, column: 9, scope: !200)
!206 = !DILocation(line: 116, column: 17, scope: !200)
!207 = !DILocation(line: 116, column: 5, scope: !200)
!208 = !DILocation(line: 117, column: 12, scope: !200)
!209 = !DILocation(line: 117, column: 40, scope: !200)
!210 = !DILocation(line: 117, column: 38, scope: !200)
!211 = !DILocation(line: 117, column: 60, scope: !200)
!212 = !DILocation(line: 117, column: 58, scope: !200)
!213 = !DILocation(line: 117, column: 90, scope: !200)
!214 = !DILocation(line: 117, column: 84, scope: !200)
!215 = !DILocation(line: 117, column: 82, scope: !200)
!216 = !DILocation(line: 118, column: 11, scope: !200)
!217 = !DILocation(line: 118, column: 9, scope: !200)
!218 = !DILocation(line: 118, column: 34, scope: !200)
!219 = !DILocation(line: 118, column: 32, scope: !200)
!220 = !DILocation(line: 118, column: 47, scope: !200)
!221 = !DILocation(line: 118, column: 45, scope: !200)
!222 = !DILocation(line: 118, column: 71, scope: !200)
!223 = !DILocation(line: 118, column: 66, scope: !200)
!224 = !DILocation(line: 118, column: 64, scope: !200)
!225 = !DILocation(line: 118, column: 87, scope: !200)
!226 = !DILocation(line: 118, column: 85, scope: !200)
!227 = !DILocation(line: 119, column: 11, scope: !200)
!228 = !DILocation(line: 119, column: 9, scope: !200)
!229 = !DILocation(line: 119, column: 30, scope: !200)
!230 = !DILocation(line: 119, column: 28, scope: !200)
!231 = !DILocation(line: 119, column: 47, scope: !200)
!232 = !DILocation(line: 119, column: 45, scope: !200)
!233 = !DILocation(line: 119, column: 65, scope: !200)
!234 = !DILocation(line: 119, column: 63, scope: !200)
!235 = !DILocation(line: 119, column: 86, scope: !200)
!236 = !DILocation(line: 119, column: 84, scope: !200)
!237 = !DILocation(line: 117, column: 5, scope: !200)
