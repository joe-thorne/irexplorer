; ModuleID = '/workspace/out/clang_warnings_01_mem2reg.ll'
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
  br i1 %cmp, label %for.body, label %for.end, !dbg !56

for.body:                                         ; preds = %for.cond
    #dbg_value(!DIArgList(i32 %total.0, i32 %i.0), !48, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_plus, DW_OP_stack_value), !47)
  br label %for.inc, !dbg !57

for.inc:                                          ; preds = %for.body
  %add1 = add nuw nsw i32 %total.0, %i.0, !dbg !59
    #dbg_value(i32 %add1, !48, !DIExpression(), !47)
  %inc = add nuw nsw i32 %i.0, 1, !dbg !60
    #dbg_value(i32 %inc, !49, !DIExpression(), !51)
  br label %for.cond, !dbg !61, !llvm.loop !62

for.end:                                          ; preds = %for.cond
  ret i32 %total.0, !dbg !64
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @is_same(i32 noundef %value) #0 !dbg !65 {
entry:
    #dbg_value(i32 %value, !66, !DIExpression(), !67)
  ret i32 1, !dbg !68
}

; Function Attrs: noinline nounwind uwtable
define dso_local zeroext i8 @small_constant() #0 !dbg !69 {
entry:
    #dbg_value(i8 44, !73, !DIExpression(), !74)
  ret i8 44, !dbg !75
}

; Function Attrs: noinline nounwind uwtable
define dso_local i64 @wide_shift(i32 noundef %value) #0 !dbg !76 {
entry:
    #dbg_value(i32 %value, !80, !DIExpression(), !81)
  ret i64 poison, !dbg !82
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @first_positive(ptr noundef %values, i32 noundef %count) #0 !dbg !83 {
entry:
    #dbg_value(ptr %values, !88, !DIExpression(), !89)
    #dbg_value(i32 %count, !90, !DIExpression(), !89)
    #dbg_value(i32 0, !91, !DIExpression(), !93)
  br label %for.cond, !dbg !94

for.cond:                                         ; preds = %for.inc, %entry
  %i.0 = phi i32 [ 0, %entry ], [ %inc, %for.inc ], !dbg !95
    #dbg_value(i32 %i.0, !91, !DIExpression(), !93)
  %cmp = icmp slt i32 %i.0, %count, !dbg !96
  br i1 %cmp, label %for.body, label %for.end, !dbg !98

for.body:                                         ; preds = %for.cond
  %idxprom = zext nneg i32 %i.0 to i64, !dbg !99
  %arrayidx = getelementptr inbounds nuw i32, ptr %values, i64 %idxprom, !dbg !99
  %0 = load i32, ptr %arrayidx, align 4, !dbg !99
  %cmp1 = icmp sgt i32 %0, 0, !dbg !102
    #dbg_value(i1 %cmp1, !103, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 32, DW_ATE_unsigned, DW_OP_stack_value), !89)
  br i1 %cmp1, label %if.then, label %if.end, !dbg !104

if.then:                                          ; preds = %for.body
  %idxprom2 = zext nneg i32 %i.0 to i64, !dbg !105
  %arrayidx3 = getelementptr inbounds nuw i32, ptr %values, i64 %idxprom2, !dbg !105
  %1 = load i32, ptr %arrayidx3, align 4, !dbg !105
  br label %return, !dbg !107

if.end:                                           ; preds = %for.body
  br label %for.inc, !dbg !108

for.inc:                                          ; preds = %if.end
  %inc = add nuw nsw i32 %i.0, 1, !dbg !109
    #dbg_value(i32 %inc, !91, !DIExpression(), !93)
  br label %for.cond, !dbg !110, !llvm.loop !111

for.end:                                          ; preds = %for.cond
  br label %return, !dbg !113

return:                                           ; preds = %for.end, %if.then
  %retval.0 = phi i32 [ %1, %if.then ], [ 0, %for.end ], !dbg !89
  ret i32 %retval.0, !dbg !114
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @skip_empty(i32 noundef %value) #0 !dbg !115 {
entry:
    #dbg_value(i32 %value, !116, !DIExpression(), !117)
  %cmp = icmp sgt i32 %value, 10, !dbg !118
  br i1 %cmp, label %if.then, label %if.end, !dbg !118

if.then:                                          ; preds = %entry
  br label %if.end, !dbg !118

if.end:                                           ; preds = %if.then, %entry
  ret i32 %value, !dbg !120
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @truncated_half() #0 !dbg !121 {
entry:
    #dbg_value(i32 2, !123, !DIExpression(), !124)
  ret i32 2, !dbg !125
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @last_of_four() #0 !dbg !126 {
entry:
    #dbg_declare(ptr @__const.last_of_four.four, !127, !DIExpression(), !131)
  ret i32 poison, !dbg !132
}

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @not_equal(i32 noundef %a, i32 noundef %b) #0 !dbg !133 {
entry:
    #dbg_value(i32 %a, !136, !DIExpression(), !137)
    #dbg_value(i32 %b, !138, !DIExpression(), !137)
  %tobool.not = icmp eq i32 %a, 0, !dbg !139
  %lnot.ext = zext i1 %tobool.not to i32, !dbg !139
  %cmp = icmp eq i32 %b, %lnot.ext, !dbg !141
  br i1 %cmp, label %if.then, label %if.end, !dbg !141

if.then:                                          ; preds = %entry
  br label %return, !dbg !142

if.end:                                           ; preds = %entry
  br label %return, !dbg !144

return:                                           ; preds = %if.end, %if.then
  %retval.0 = phi i32 [ 1, %if.then ], [ 0, %if.end ], !dbg !137
  ret i32 %retval.0, !dbg !145
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @array_size(ptr noundef %values) #0 !dbg !146 {
entry:
    #dbg_value(ptr %values, !150, !DIExpression(), !151)
  ret i32 2, !dbg !152
}

; Function Attrs: noinline nounwind uwtable
define dso_local void @print_total(i64 noundef %total, double noundef %mean) #0 !dbg !153 {
entry:
    #dbg_value(i64 %total, !157, !DIExpression(), !158)
    #dbg_value(double %mean, !159, !DIExpression(), !158)
  %call = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i64 noundef %total) #3, !dbg !160
  %call1 = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.1, double noundef %mean) #3, !dbg !161
  ret void, !dbg !162
}

declare i32 @printf(ptr noundef, ...) #2

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @scaled_sum(ptr noundef %values, i32 noundef %count) #0 !dbg !163 {
entry:
    #dbg_value(ptr %values, !164, !DIExpression(), !165)
    #dbg_value(i32 %count, !166, !DIExpression(), !165)
    #dbg_value(i32 0, !167, !DIExpression(), !165)
    #dbg_value(i32 0, !168, !DIExpression(), !170)
  br label %for.cond, !dbg !171

for.cond:                                         ; preds = %for.inc, %entry
  %total.0 = phi i32 [ 0, %entry ], [ %add, %for.inc ], !dbg !165
  %i.0 = phi i32 [ 0, %entry ], [ %inc, %for.inc ], !dbg !172
    #dbg_value(i32 %i.0, !168, !DIExpression(), !170)
    #dbg_value(i32 %total.0, !167, !DIExpression(), !165)
  %cmp = icmp slt i32 %i.0, %count, !dbg !173
  br i1 %cmp, label %for.body, label %for.end, !dbg !175

for.body:                                         ; preds = %for.cond
  %idxprom = zext nneg i32 %i.0 to i64, !dbg !176
  %arrayidx = getelementptr inbounds nuw i32, ptr %values, i64 %idxprom, !dbg !176
  %0 = load i32, ptr %arrayidx, align 4, !dbg !176
  %mul = shl nsw i32 %0, 1, !dbg !179
  %add = add nsw i32 %total.0, %mul, !dbg !180
    #dbg_value(i32 %add, !167, !DIExpression(), !165)
  %tobool.not = icmp eq i32 %add, 0, !dbg !181
  br i1 %tobool.not, label %if.end, label %if.then, !dbg !181

if.then:                                          ; preds = %for.body
  br label %if.end, !dbg !182

if.end:                                           ; preds = %if.then, %for.body
  br label %for.inc, !dbg !184

for.inc:                                          ; preds = %if.end
  %inc = add nuw nsw i32 %i.0, 1, !dbg !185
    #dbg_value(i32 %inc, !168, !DIExpression(), !170)
  br label %for.cond, !dbg !186, !llvm.loop !187

for.end:                                          ; preds = %for.cond
  ret i32 %total.0, !dbg !189
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @clamp(i32 noundef %value) #0 !dbg !190 {
entry:
    #dbg_value(i32 %value, !191, !DIExpression(), !192)
    #dbg_value(i8 56, !193, !DIExpression(), !192)
    #dbg_value(i8 -56, !194, !DIExpression(), !192)
  %cmp = icmp slt i32 %value, 56, !dbg !195
  br i1 %cmp, label %if.then, label %if.end, !dbg !195

if.then:                                          ; preds = %entry
  br label %return, !dbg !197

if.end:                                           ; preds = %entry
  br i1 true, label %if.then6, label %if.end8, !dbg !199

if.then6:                                         ; preds = %if.end
  br label %return, !dbg !201

if.end8:                                          ; preds = %if.end
  br label %return, !dbg !203

return:                                           ; preds = %if.end8, %if.then6, %if.then
  %retval.0 = phi i32 [ 56, %if.then ], [ -56, %if.then6 ], [ poison, %if.end8 ], !dbg !192
  ret i32 %retval.0, !dbg !204
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @max_of(ptr noundef %values, i32 noundef %count) #0 !dbg !205 {
entry:
    #dbg_value(ptr %values, !206, !DIExpression(), !207)
    #dbg_value(i32 %count, !208, !DIExpression(), !207)
  %0 = load i32, ptr %values, align 4, !dbg !209
    #dbg_value(i32 %0, !210, !DIExpression(), !207)
    #dbg_value(i32 1, !211, !DIExpression(), !213)
  br label %for.cond, !dbg !214

for.cond:                                         ; preds = %for.inc, %entry
  %best.0 = phi i32 [ %0, %entry ], [ %cond, %for.inc ], !dbg !207
  %i.0 = phi i32 [ 1, %entry ], [ %inc, %for.inc ], !dbg !215
    #dbg_value(i32 %i.0, !211, !DIExpression(), !213)
    #dbg_value(i32 %best.0, !210, !DIExpression(), !207)
  %cmp = icmp slt i32 %i.0, %count, !dbg !216
  br i1 %cmp, label %for.body, label %for.end, !dbg !218

for.body:                                         ; preds = %for.cond
  %idxprom = zext nneg i32 %i.0 to i64, !dbg !219
  %arrayidx1 = getelementptr inbounds nuw i32, ptr %values, i64 %idxprom, !dbg !219
  %1 = load i32, ptr %arrayidx1, align 4, !dbg !219
  %cmp2 = icmp sgt i32 %1, %best.0, !dbg !222
  br i1 %cmp2, label %cond.true, label %cond.false, !dbg !219

cond.true:                                        ; preds = %for.body
  %idxprom3 = zext nneg i32 %i.0 to i64, !dbg !223
  %arrayidx4 = getelementptr inbounds nuw i32, ptr %values, i64 %idxprom3, !dbg !223
  %2 = load i32, ptr %arrayidx4, align 4, !dbg !223
  br label %cond.end, !dbg !219

cond.false:                                       ; preds = %for.body
  br label %cond.end, !dbg !219

cond.end:                                         ; preds = %cond.false, %cond.true
  %cond = phi i32 [ %2, %cond.true ], [ %best.0, %cond.false ], !dbg !219
    #dbg_value(i32 %cond, !210, !DIExpression(), !207)
  %tobool.not = icmp eq i32 %cond, 0, !dbg !224
  br i1 %tobool.not, label %if.end, label %if.then, !dbg !224

if.then:                                          ; preds = %cond.end
  br label %if.end, !dbg !225

if.end:                                           ; preds = %if.then, %cond.end
  br label %for.inc, !dbg !227

for.inc:                                          ; preds = %if.end
  %inc = add nuw nsw i32 %i.0, 1, !dbg !228
    #dbg_value(i32 %inc, !211, !DIExpression(), !213)
  br label %for.cond, !dbg !229, !llvm.loop !230

for.end:                                          ; preds = %for.cond
  ret i32 %best.0, !dbg !232
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @bump(i32 noundef %i) #0 !dbg !233 {
entry:
    #dbg_value(i32 %i, !234, !DIExpression(), !235)
    #dbg_value(i32 %i, !234, !DIExpression(DW_OP_plus_uconst, 1, DW_OP_stack_value), !235)
    #dbg_value(i32 %i, !234, !DIExpression(DW_OP_plus_uconst, 1, DW_OP_stack_value), !235)
  br i1 false, label %cond.true, label %cond.false, !dbg !236

cond.true:                                        ; preds = %entry
  br label %cond.end, !dbg !236

cond.false:                                       ; preds = %entry
  %add = add nsw i32 %i, 1, !dbg !237
    #dbg_value(i32 %add, !234, !DIExpression(), !235)
  br label %cond.end, !dbg !236

cond.end:                                         ; preds = %cond.false, %cond.true
  %cond = phi i32 [ poison, %cond.true ], [ %add, %cond.false ], !dbg !236
  ret i32 %cond, !dbg !238
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @main() #0 !dbg !239 {
entry:
  %values = alloca [6 x i32], align 16
    #dbg_declare(ptr %values, !240, !DIExpression(), !244)
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(24) %values, ptr noundef nonnull align 16 dereferenceable(24) @__const.main.values, i64 24, i1 false), !dbg !244
  %call = call i32 @sum_to(i32 noundef 10), !dbg !245
  %conv = sext i32 %call to i64, !dbg !245
  call void @print_total(i64 noundef %conv, double noundef 2.500000e+00), !dbg !246
  %call1 = call i32 @first_positive(ptr noundef nonnull %values, i32 noundef 6), !dbg !247
  %call3 = call i32 @max_of(ptr noundef nonnull %values, i32 noundef 6), !dbg !248
  %add = add nsw i32 %call1, %call3, !dbg !249
  %call5 = call i32 @scaled_sum(ptr noundef nonnull %values, i32 noundef 6), !dbg !250
  %add6 = add nsw i32 %add, %call5, !dbg !251
  %arrayidx = getelementptr inbounds nuw i8, ptr %values, i64 20, !dbg !252
  %0 = load i32, ptr %arrayidx, align 4, !dbg !252
  %call7 = call i32 @clamp(i32 noundef %0), !dbg !253
  %add8 = add nsw i32 %add6, %call7, !dbg !254
  %call9 = call i32 @count_set_bits(i32 noundef 255), !dbg !255
  %add10 = add nsw i32 %add8, %call9, !dbg !256
  %call11 = call i32 @is_same(i32 noundef 1), !dbg !257
  %add12 = add nsw i32 %add10, %call11, !dbg !258
  %call13 = call zeroext i8 @small_constant(), !dbg !259
  %conv14 = zext i8 %call13 to i32, !dbg !259
  %add15 = add nsw i32 %add12, %conv14, !dbg !260
  %call16 = call i64 @wide_shift(i32 noundef 1), !dbg !261
  %conv17 = trunc i64 %call16 to i32, !dbg !262
  %add18 = add nsw i32 %add15, %conv17, !dbg !263
  %call19 = call i32 @skip_empty(i32 noundef 3), !dbg !264
  %add20 = add nsw i32 %add18, %call19, !dbg !265
  %call21 = call i32 @truncated_half(), !dbg !266
  %add22 = add nsw i32 %add20, %call21, !dbg !267
  %call23 = call i32 @last_of_four(), !dbg !268
  %add24 = add nsw i32 %add22, %call23, !dbg !269
  %call25 = call i32 @not_equal(i32 noundef 1, i32 noundef 2), !dbg !270
  %add26 = add nsw i32 %add24, %call25, !dbg !271
  %call28 = call i32 @array_size(ptr noundef nonnull %values), !dbg !272
  %add29 = add nsw i32 %add26, %call28, !dbg !273
  %call30 = call i32 @bump(i32 noundef 2), !dbg !274
  %add31 = add nsw i32 %add29, %call30, !dbg !275
  ret i32 %add31, !dbg !276
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
!57 = !DILocation(line: 19, column: 5, scope: !58)
!58 = distinct !DILexicalBlock(scope: !55, file: !2, line: 16, column: 37)
!59 = !DILocation(line: 18, column: 15, scope: !58)
!60 = !DILocation(line: 16, column: 33, scope: !55)
!61 = !DILocation(line: 16, column: 5, scope: !55)
!62 = distinct !{!62, !56, !63, !41}
!63 = !DILocation(line: 19, column: 5, scope: !50)
!64 = !DILocation(line: 20, column: 5, scope: !43)
!65 = distinct !DISubprogram(name: "is_same", scope: !2, file: !2, line: 23, type: !44, scopeLine: 23, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!66 = !DILocalVariable(name: "value", arg: 1, scope: !65, file: !2, line: 23, type: !15)
!67 = !DILocation(line: 0, scope: !65)
!68 = !DILocation(line: 24, column: 5, scope: !65)
!69 = distinct !DISubprogram(name: "small_constant", scope: !2, file: !2, line: 27, type: !70, scopeLine: 27, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!70 = !DISubroutineType(types: !71)
!71 = !{!72}
!72 = !DIBasicType(name: "unsigned char", size: 8, encoding: DW_ATE_unsigned_char)
!73 = !DILocalVariable(name: "byte", scope: !69, file: !2, line: 28, type: !72)
!74 = !DILocation(line: 0, scope: !69)
!75 = !DILocation(line: 29, column: 5, scope: !69)
!76 = distinct !DISubprogram(name: "wide_shift", scope: !2, file: !2, line: 32, type: !77, scopeLine: 32, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!77 = !DISubroutineType(types: !78)
!78 = !{!79, !15}
!79 = !DIBasicType(name: "long", size: 64, encoding: DW_ATE_signed)
!80 = !DILocalVariable(name: "value", arg: 1, scope: !76, file: !2, line: 32, type: !15)
!81 = !DILocation(line: 0, scope: !76)
!82 = !DILocation(line: 33, column: 5, scope: !76)
!83 = distinct !DISubprogram(name: "first_positive", scope: !2, file: !2, line: 36, type: !84, scopeLine: 36, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!84 = !DISubroutineType(types: !85)
!85 = !{!15, !86, !15}
!86 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !87, size: 64)
!87 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !15)
!88 = !DILocalVariable(name: "values", arg: 1, scope: !83, file: !2, line: 36, type: !86)
!89 = !DILocation(line: 0, scope: !83)
!90 = !DILocalVariable(name: "count", arg: 2, scope: !83, file: !2, line: 36, type: !15)
!91 = !DILocalVariable(name: "i", scope: !92, file: !2, line: 38, type: !15)
!92 = distinct !DILexicalBlock(scope: !83, file: !2, line: 38, column: 5)
!93 = !DILocation(line: 0, scope: !92)
!94 = !DILocation(line: 38, column: 10, scope: !92)
!95 = !DILocation(line: 38, scope: !92)
!96 = !DILocation(line: 38, column: 23, scope: !97)
!97 = distinct !DILexicalBlock(scope: !92, file: !2, line: 38, column: 5)
!98 = !DILocation(line: 38, column: 5, scope: !92)
!99 = !DILocation(line: 39, column: 21, scope: !100)
!100 = distinct !DILexicalBlock(scope: !101, file: !2, line: 39, column: 13)
!101 = distinct !DILexicalBlock(scope: !97, file: !2, line: 38, column: 37)
!102 = !DILocation(line: 39, column: 31, scope: !100)
!103 = !DILocalVariable(name: "found", scope: !83, file: !2, line: 37, type: !15)
!104 = !DILocation(line: 39, column: 19, scope: !100)
!105 = !DILocation(line: 40, column: 20, scope: !106)
!106 = distinct !DILexicalBlock(scope: !100, file: !2, line: 39, column: 36)
!107 = !DILocation(line: 40, column: 13, scope: !106)
!108 = !DILocation(line: 42, column: 5, scope: !101)
!109 = !DILocation(line: 38, column: 33, scope: !97)
!110 = !DILocation(line: 38, column: 5, scope: !97)
!111 = distinct !{!111, !98, !112, !41}
!112 = !DILocation(line: 42, column: 5, scope: !92)
!113 = !DILocation(line: 43, column: 5, scope: !83)
!114 = !DILocation(line: 44, column: 1, scope: !83)
!115 = distinct !DISubprogram(name: "skip_empty", scope: !2, file: !2, line: 46, type: !44, scopeLine: 46, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!116 = !DILocalVariable(name: "value", arg: 1, scope: !115, file: !2, line: 46, type: !15)
!117 = !DILocation(line: 0, scope: !115)
!118 = !DILocation(line: 47, column: 15, scope: !119)
!119 = distinct !DILexicalBlock(scope: !115, file: !2, line: 47, column: 9)
!120 = !DILocation(line: 48, column: 5, scope: !115)
!121 = distinct !DISubprogram(name: "truncated_half", scope: !2, file: !2, line: 51, type: !122, scopeLine: 51, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!122 = !DISubroutineType(types: !14)
!123 = !DILocalVariable(name: "half", scope: !121, file: !2, line: 52, type: !15)
!124 = !DILocation(line: 0, scope: !121)
!125 = !DILocation(line: 53, column: 5, scope: !121)
!126 = distinct !DISubprogram(name: "last_of_four", scope: !2, file: !2, line: 56, type: !122, scopeLine: 56, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!127 = !DILocalVariable(name: "four", scope: !126, file: !2, line: 57, type: !128)
!128 = !DICompositeType(tag: DW_TAG_array_type, baseType: !15, size: 128, elements: !129)
!129 = !{!130}
!130 = !DISubrange(count: 4)
!131 = !DILocation(line: 57, column: 9, scope: !126)
!132 = !DILocation(line: 58, column: 5, scope: !126)
!133 = distinct !DISubprogram(name: "not_equal", scope: !2, file: !2, line: 61, type: !134, scopeLine: 61, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!134 = !DISubroutineType(types: !135)
!135 = !{!15, !15, !15}
!136 = !DILocalVariable(name: "a", arg: 1, scope: !133, file: !2, line: 61, type: !15)
!137 = !DILocation(line: 0, scope: !133)
!138 = !DILocalVariable(name: "b", arg: 2, scope: !133, file: !2, line: 61, type: !15)
!139 = !DILocation(line: 62, column: 9, scope: !140)
!140 = distinct !DILexicalBlock(scope: !133, file: !2, line: 62, column: 9)
!141 = !DILocation(line: 62, column: 12, scope: !140)
!142 = !DILocation(line: 63, column: 9, scope: !143)
!143 = distinct !DILexicalBlock(scope: !140, file: !2, line: 62, column: 18)
!144 = !DILocation(line: 65, column: 5, scope: !133)
!145 = !DILocation(line: 66, column: 1, scope: !133)
!146 = distinct !DISubprogram(name: "array_size", scope: !2, file: !2, line: 68, type: !147, scopeLine: 68, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!147 = !DISubroutineType(types: !148)
!148 = !{!15, !149}
!149 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !15, size: 64)
!150 = !DILocalVariable(name: "values", arg: 1, scope: !146, file: !2, line: 68, type: !149)
!151 = !DILocation(line: 0, scope: !146)
!152 = !DILocation(line: 69, column: 5, scope: !146)
!153 = distinct !DISubprogram(name: "print_total", scope: !2, file: !2, line: 72, type: !154, scopeLine: 72, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!154 = !DISubroutineType(types: !155)
!155 = !{null, !79, !156}
!156 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!157 = !DILocalVariable(name: "total", arg: 1, scope: !153, file: !2, line: 72, type: !79)
!158 = !DILocation(line: 0, scope: !153)
!159 = !DILocalVariable(name: "mean", arg: 2, scope: !153, file: !2, line: 72, type: !156)
!160 = !DILocation(line: 73, column: 5, scope: !153)
!161 = !DILocation(line: 74, column: 5, scope: !153)
!162 = !DILocation(line: 75, column: 1, scope: !153)
!163 = distinct !DISubprogram(name: "scaled_sum", scope: !2, file: !2, line: 77, type: !84, scopeLine: 77, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!164 = !DILocalVariable(name: "values", arg: 1, scope: !163, file: !2, line: 77, type: !86)
!165 = !DILocation(line: 0, scope: !163)
!166 = !DILocalVariable(name: "count", arg: 2, scope: !163, file: !2, line: 77, type: !15)
!167 = !DILocalVariable(name: "total", scope: !163, file: !2, line: 78, type: !15)
!168 = !DILocalVariable(name: "i", scope: !169, file: !2, line: 79, type: !15)
!169 = distinct !DILexicalBlock(scope: !163, file: !2, line: 79, column: 5)
!170 = !DILocation(line: 0, scope: !169)
!171 = !DILocation(line: 79, column: 10, scope: !169)
!172 = !DILocation(line: 79, scope: !169)
!173 = !DILocation(line: 79, column: 23, scope: !174)
!174 = distinct !DILexicalBlock(scope: !169, file: !2, line: 79, column: 5)
!175 = !DILocation(line: 79, column: 5, scope: !169)
!176 = !DILocation(line: 80, column: 29, scope: !177)
!177 = distinct !DILexicalBlock(scope: !178, file: !2, line: 80, column: 13)
!178 = distinct !DILexicalBlock(scope: !174, file: !2, line: 79, column: 37)
!179 = !DILocation(line: 80, column: 39, scope: !177)
!180 = !DILocation(line: 80, column: 27, scope: !177)
!181 = !DILocation(line: 80, column: 19, scope: !177)
!182 = !DILocation(line: 82, column: 9, scope: !183)
!183 = distinct !DILexicalBlock(scope: !177, file: !2, line: 80, column: 44)
!184 = !DILocation(line: 83, column: 5, scope: !178)
!185 = !DILocation(line: 79, column: 33, scope: !174)
!186 = !DILocation(line: 79, column: 5, scope: !174)
!187 = distinct !{!187, !175, !188, !41}
!188 = !DILocation(line: 83, column: 5, scope: !169)
!189 = !DILocation(line: 84, column: 5, scope: !163)
!190 = distinct !DISubprogram(name: "clamp", scope: !2, file: !2, line: 87, type: !44, scopeLine: 87, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!191 = !DILocalVariable(name: "value", arg: 1, scope: !190, file: !2, line: 87, type: !15)
!192 = !DILocation(line: 0, scope: !190)
!193 = !DILocalVariable(name: "low", scope: !190, file: !2, line: 88, type: !4)
!194 = !DILocalVariable(name: "high", scope: !190, file: !2, line: 89, type: !4)
!195 = !DILocation(line: 90, column: 15, scope: !196)
!196 = distinct !DILexicalBlock(scope: !190, file: !2, line: 90, column: 9)
!197 = !DILocation(line: 91, column: 9, scope: !198)
!198 = distinct !DILexicalBlock(scope: !196, file: !2, line: 90, column: 22)
!199 = !DILocation(line: 93, column: 15, scope: !200)
!200 = distinct !DILexicalBlock(scope: !190, file: !2, line: 93, column: 9)
!201 = !DILocation(line: 94, column: 9, scope: !202)
!202 = distinct !DILexicalBlock(scope: !200, file: !2, line: 93, column: 23)
!203 = !DILocation(line: 96, column: 5, scope: !190)
!204 = !DILocation(line: 97, column: 1, scope: !190)
!205 = distinct !DISubprogram(name: "max_of", scope: !2, file: !2, line: 99, type: !84, scopeLine: 99, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!206 = !DILocalVariable(name: "values", arg: 1, scope: !205, file: !2, line: 99, type: !86)
!207 = !DILocation(line: 0, scope: !205)
!208 = !DILocalVariable(name: "count", arg: 2, scope: !205, file: !2, line: 99, type: !15)
!209 = !DILocation(line: 100, column: 16, scope: !205)
!210 = !DILocalVariable(name: "best", scope: !205, file: !2, line: 100, type: !15)
!211 = !DILocalVariable(name: "i", scope: !212, file: !2, line: 101, type: !15)
!212 = distinct !DILexicalBlock(scope: !205, file: !2, line: 101, column: 5)
!213 = !DILocation(line: 0, scope: !212)
!214 = !DILocation(line: 101, column: 10, scope: !212)
!215 = !DILocation(line: 101, scope: !212)
!216 = !DILocation(line: 101, column: 23, scope: !217)
!217 = distinct !DILexicalBlock(scope: !212, file: !2, line: 101, column: 5)
!218 = !DILocation(line: 101, column: 5, scope: !212)
!219 = !DILocation(line: 102, column: 20, scope: !220)
!220 = distinct !DILexicalBlock(scope: !221, file: !2, line: 102, column: 13)
!221 = distinct !DILexicalBlock(scope: !217, file: !2, line: 101, column: 37)
!222 = !DILocation(line: 102, column: 30, scope: !220)
!223 = !DILocation(line: 102, column: 39, scope: !220)
!224 = !DILocation(line: 102, column: 18, scope: !220)
!225 = !DILocation(line: 104, column: 9, scope: !226)
!226 = distinct !DILexicalBlock(scope: !220, file: !2, line: 102, column: 57)
!227 = !DILocation(line: 105, column: 5, scope: !221)
!228 = !DILocation(line: 101, column: 33, scope: !217)
!229 = !DILocation(line: 101, column: 5, scope: !217)
!230 = distinct !{!230, !218, !231, !41}
!231 = !DILocation(line: 105, column: 5, scope: !212)
!232 = !DILocation(line: 106, column: 5, scope: !205)
!233 = distinct !DISubprogram(name: "bump", scope: !2, file: !2, line: 109, type: !44, scopeLine: 109, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!234 = !DILocalVariable(name: "i", arg: 1, scope: !233, file: !2, line: 109, type: !15)
!235 = !DILocation(line: 0, scope: !233)
!236 = !DILocation(line: 111, column: 12, scope: !233)
!237 = !DILocation(line: 110, column: 13, scope: !233)
!238 = !DILocation(line: 111, column: 5, scope: !233)
!239 = distinct !DISubprogram(name: "main", scope: !2, file: !2, line: 114, type: !122, scopeLine: 114, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!240 = !DILocalVariable(name: "values", scope: !239, file: !2, line: 115, type: !241)
!241 = !DICompositeType(tag: DW_TAG_array_type, baseType: !15, size: 192, elements: !242)
!242 = !{!243}
!243 = !DISubrange(count: 6)
!244 = !DILocation(line: 115, column: 9, scope: !239)
!245 = !DILocation(line: 116, column: 17, scope: !239)
!246 = !DILocation(line: 116, column: 5, scope: !239)
!247 = !DILocation(line: 117, column: 12, scope: !239)
!248 = !DILocation(line: 117, column: 40, scope: !239)
!249 = !DILocation(line: 117, column: 38, scope: !239)
!250 = !DILocation(line: 117, column: 60, scope: !239)
!251 = !DILocation(line: 117, column: 58, scope: !239)
!252 = !DILocation(line: 117, column: 90, scope: !239)
!253 = !DILocation(line: 117, column: 84, scope: !239)
!254 = !DILocation(line: 117, column: 82, scope: !239)
!255 = !DILocation(line: 118, column: 11, scope: !239)
!256 = !DILocation(line: 118, column: 9, scope: !239)
!257 = !DILocation(line: 118, column: 34, scope: !239)
!258 = !DILocation(line: 118, column: 32, scope: !239)
!259 = !DILocation(line: 118, column: 47, scope: !239)
!260 = !DILocation(line: 118, column: 45, scope: !239)
!261 = !DILocation(line: 118, column: 71, scope: !239)
!262 = !DILocation(line: 118, column: 66, scope: !239)
!263 = !DILocation(line: 118, column: 64, scope: !239)
!264 = !DILocation(line: 118, column: 87, scope: !239)
!265 = !DILocation(line: 118, column: 85, scope: !239)
!266 = !DILocation(line: 119, column: 11, scope: !239)
!267 = !DILocation(line: 119, column: 9, scope: !239)
!268 = !DILocation(line: 119, column: 30, scope: !239)
!269 = !DILocation(line: 119, column: 28, scope: !239)
!270 = !DILocation(line: 119, column: 47, scope: !239)
!271 = !DILocation(line: 119, column: 45, scope: !239)
!272 = !DILocation(line: 119, column: 65, scope: !239)
!273 = !DILocation(line: 119, column: 63, scope: !239)
!274 = !DILocation(line: 119, column: 86, scope: !239)
!275 = !DILocation(line: 119, column: 84, scope: !239)
!276 = !DILocation(line: 117, column: 5, scope: !239)
