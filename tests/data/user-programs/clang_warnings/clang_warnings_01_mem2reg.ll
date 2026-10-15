; ModuleID = '/workspace/out/clang_warnings_O0.bc'
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
  %tobool = icmp ne i32 %and, 0, !dbg !33
  br i1 %tobool, label %while.body, label %while.end, !dbg !33

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
  %add = add nsw i32 %total.0, %i.0, !dbg !57
  %add1 = add nsw i32 %total.0, %i.0, !dbg !59
    #dbg_value(i32 %add1, !48, !DIExpression(), !47)
  br label %for.inc, !dbg !60

for.inc:                                          ; preds = %for.body
  %inc = add nsw i32 %i.0, 1, !dbg !61
    #dbg_value(i32 %inc, !49, !DIExpression(), !51)
  br label %for.cond, !dbg !62, !llvm.loop !63

for.end:                                          ; preds = %for.cond
  ret i32 %total.0, !dbg !65
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @is_same(i32 noundef %value) #0 !dbg !66 {
entry:
    #dbg_value(i32 %value, !67, !DIExpression(), !68)
  %cmp = icmp eq i32 %value, %value, !dbg !69
  %conv = zext i1 %cmp to i32, !dbg !69
  ret i32 %conv, !dbg !70
}

; Function Attrs: noinline nounwind uwtable
define dso_local zeroext i8 @small_constant() #0 !dbg !71 {
entry:
    #dbg_value(i8 44, !75, !DIExpression(), !76)
  ret i8 44, !dbg !77
}

; Function Attrs: noinline nounwind uwtable
define dso_local i64 @wide_shift(i32 noundef %value) #0 !dbg !78 {
entry:
    #dbg_value(i32 %value, !82, !DIExpression(), !83)
  %shl = shl i32 %value, 40, !dbg !84
  %conv = sext i32 %shl to i64, !dbg !85
  ret i64 %conv, !dbg !86
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @first_positive(ptr noundef %values, i32 noundef %count) #0 !dbg !87 {
entry:
    #dbg_value(ptr %values, !92, !DIExpression(), !93)
    #dbg_value(i32 %count, !94, !DIExpression(), !93)
    #dbg_value(i32 0, !95, !DIExpression(), !97)
  br label %for.cond, !dbg !98

for.cond:                                         ; preds = %for.inc, %entry
  %i.0 = phi i32 [ 0, %entry ], [ %inc, %for.inc ], !dbg !99
    #dbg_value(i32 %i.0, !95, !DIExpression(), !97)
  %cmp = icmp slt i32 %i.0, %count, !dbg !100
  br i1 %cmp, label %for.body, label %for.end, !dbg !102

for.body:                                         ; preds = %for.cond
  %idxprom = sext i32 %i.0 to i64, !dbg !103
  %arrayidx = getelementptr inbounds i32, ptr %values, i64 %idxprom, !dbg !103
  %0 = load i32, ptr %arrayidx, align 4, !dbg !103
  %cmp1 = icmp sgt i32 %0, 0, !dbg !106
  %conv = zext i1 %cmp1 to i32, !dbg !106
    #dbg_value(i32 %conv, !107, !DIExpression(), !93)
  br i1 %cmp1, label %if.then, label %if.end, !dbg !108

if.then:                                          ; preds = %for.body
  %idxprom2 = sext i32 %i.0 to i64, !dbg !109
  %arrayidx3 = getelementptr inbounds i32, ptr %values, i64 %idxprom2, !dbg !109
  %1 = load i32, ptr %arrayidx3, align 4, !dbg !109
  br label %return, !dbg !111

if.end:                                           ; preds = %for.body
  br label %for.inc, !dbg !112

for.inc:                                          ; preds = %if.end
  %inc = add nsw i32 %i.0, 1, !dbg !113
    #dbg_value(i32 %inc, !95, !DIExpression(), !97)
  br label %for.cond, !dbg !114, !llvm.loop !115

for.end:                                          ; preds = %for.cond
  br label %return, !dbg !117

return:                                           ; preds = %for.end, %if.then
  %retval.0 = phi i32 [ %1, %if.then ], [ 0, %for.end ], !dbg !93
  ret i32 %retval.0, !dbg !118
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @skip_empty(i32 noundef %value) #0 !dbg !119 {
entry:
    #dbg_value(i32 %value, !120, !DIExpression(), !121)
  %cmp = icmp sgt i32 %value, 10, !dbg !122
  br i1 %cmp, label %if.then, label %if.end, !dbg !122

if.then:                                          ; preds = %entry
  br label %if.end, !dbg !122

if.end:                                           ; preds = %if.then, %entry
  ret i32 %value, !dbg !124
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @truncated_half() #0 !dbg !125 {
entry:
    #dbg_value(i32 2, !127, !DIExpression(), !128)
  ret i32 2, !dbg !129
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @last_of_four() #0 !dbg !130 {
entry:
  %four = alloca [4 x i32], align 16
    #dbg_declare(ptr %four, !131, !DIExpression(), !135)
  call void @llvm.memcpy.p0.p0.i64(ptr align 16 %four, ptr align 16 @__const.last_of_four.four, i64 16, i1 false), !dbg !135
  %arrayidx = getelementptr inbounds [4 x i32], ptr %four, i64 0, i64 4, !dbg !136
  %0 = load i32, ptr %arrayidx, align 16, !dbg !136
  ret i32 %0, !dbg !137
}

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @not_equal(i32 noundef %a, i32 noundef %b) #0 !dbg !138 {
entry:
    #dbg_value(i32 %a, !141, !DIExpression(), !142)
    #dbg_value(i32 %b, !143, !DIExpression(), !142)
  %tobool = icmp ne i32 %a, 0, !dbg !144
  %lnot = xor i1 %tobool, true, !dbg !144
  %lnot.ext = zext i1 %lnot to i32, !dbg !144
  %cmp = icmp eq i32 %lnot.ext, %b, !dbg !146
  br i1 %cmp, label %if.then, label %if.end, !dbg !146

if.then:                                          ; preds = %entry
  br label %return, !dbg !147

if.end:                                           ; preds = %entry
  br label %return, !dbg !149

return:                                           ; preds = %if.end, %if.then
  %retval.0 = phi i32 [ 1, %if.then ], [ 0, %if.end ], !dbg !142
  ret i32 %retval.0, !dbg !150
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @array_size(ptr noundef %values) #0 !dbg !151 {
entry:
    #dbg_value(ptr %values, !155, !DIExpression(), !156)
  ret i32 2, !dbg !157
}

; Function Attrs: noinline nounwind uwtable
define dso_local void @print_total(i64 noundef %total, double noundef %mean) #0 !dbg !158 {
entry:
    #dbg_value(i64 %total, !162, !DIExpression(), !163)
    #dbg_value(double %mean, !164, !DIExpression(), !163)
  %call = call i32 (ptr, ...) @printf(ptr noundef @.str, i64 noundef %total), !dbg !165
  %call1 = call i32 (ptr, ...) @printf(ptr noundef @.str.1, double noundef %mean), !dbg !166
  ret void, !dbg !167
}

declare i32 @printf(ptr noundef, ...) #2

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @scaled_sum(ptr noundef %values, i32 noundef %count) #0 !dbg !168 {
entry:
    #dbg_value(ptr %values, !169, !DIExpression(), !170)
    #dbg_value(i32 %count, !171, !DIExpression(), !170)
    #dbg_value(i32 0, !172, !DIExpression(), !170)
    #dbg_value(i32 0, !173, !DIExpression(), !175)
  br label %for.cond, !dbg !176

for.cond:                                         ; preds = %for.inc, %entry
  %total.0 = phi i32 [ 0, %entry ], [ %add, %for.inc ], !dbg !170
  %i.0 = phi i32 [ 0, %entry ], [ %inc, %for.inc ], !dbg !177
    #dbg_value(i32 %i.0, !173, !DIExpression(), !175)
    #dbg_value(i32 %total.0, !172, !DIExpression(), !170)
  %cmp = icmp slt i32 %i.0, %count, !dbg !178
  br i1 %cmp, label %for.body, label %for.end, !dbg !180

for.body:                                         ; preds = %for.cond
  %idxprom = sext i32 %i.0 to i64, !dbg !181
  %arrayidx = getelementptr inbounds i32, ptr %values, i64 %idxprom, !dbg !181
  %0 = load i32, ptr %arrayidx, align 4, !dbg !181
  %mul = mul nsw i32 %0, 2, !dbg !184
  %add = add nsw i32 %total.0, %mul, !dbg !185
    #dbg_value(i32 %add, !172, !DIExpression(), !170)
  %tobool = icmp ne i32 %add, 0, !dbg !186
  br i1 %tobool, label %if.then, label %if.end, !dbg !186

if.then:                                          ; preds = %for.body
  %cmp1 = icmp eq i32 %add, 0, !dbg !187
  %conv = zext i1 %cmp1 to i32, !dbg !187
  br label %if.end, !dbg !189

if.end:                                           ; preds = %if.then, %for.body
  br label %for.inc, !dbg !190

for.inc:                                          ; preds = %if.end
  %inc = add nsw i32 %i.0, 1, !dbg !191
    #dbg_value(i32 %inc, !173, !DIExpression(), !175)
  br label %for.cond, !dbg !192, !llvm.loop !193

for.end:                                          ; preds = %for.cond
  ret i32 %total.0, !dbg !195
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @clamp(i32 noundef %value) #0 !dbg !196 {
entry:
    #dbg_value(i32 %value, !197, !DIExpression(), !198)
    #dbg_value(i8 56, !199, !DIExpression(), !198)
    #dbg_value(i8 -56, !200, !DIExpression(), !198)
  %conv = sext i8 56 to i32, !dbg !201
  %cmp = icmp slt i32 %value, %conv, !dbg !203
  br i1 %cmp, label %if.then, label %if.end, !dbg !203

if.then:                                          ; preds = %entry
  %conv2 = sext i8 56 to i32, !dbg !204
  br label %return, !dbg !206

if.end:                                           ; preds = %entry
  %conv3 = sext i8 -56 to i32, !dbg !207
  %cmp4 = icmp sgt i32 %value, %conv3, !dbg !209
  br i1 %cmp4, label %if.then6, label %if.end8, !dbg !209

if.then6:                                         ; preds = %if.end
  %conv7 = sext i8 -56 to i32, !dbg !210
  br label %return, !dbg !212

if.end8:                                          ; preds = %if.end
  br label %return, !dbg !213

return:                                           ; preds = %if.end8, %if.then6, %if.then
  %retval.0 = phi i32 [ %conv2, %if.then ], [ %conv7, %if.then6 ], [ %value, %if.end8 ], !dbg !198
  ret i32 %retval.0, !dbg !214
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @max_of(ptr noundef %values, i32 noundef %count) #0 !dbg !215 {
entry:
    #dbg_value(ptr %values, !216, !DIExpression(), !217)
    #dbg_value(i32 %count, !218, !DIExpression(), !217)
  %arrayidx = getelementptr inbounds i32, ptr %values, i64 0, !dbg !219
  %0 = load i32, ptr %arrayidx, align 4, !dbg !219
    #dbg_value(i32 %0, !220, !DIExpression(), !217)
    #dbg_value(i32 1, !221, !DIExpression(), !223)
  br label %for.cond, !dbg !224

for.cond:                                         ; preds = %for.inc, %entry
  %best.0 = phi i32 [ %0, %entry ], [ %cond, %for.inc ], !dbg !217
  %i.0 = phi i32 [ 1, %entry ], [ %inc, %for.inc ], !dbg !225
    #dbg_value(i32 %i.0, !221, !DIExpression(), !223)
    #dbg_value(i32 %best.0, !220, !DIExpression(), !217)
  %cmp = icmp slt i32 %i.0, %count, !dbg !226
  br i1 %cmp, label %for.body, label %for.end, !dbg !228

for.body:                                         ; preds = %for.cond
  %idxprom = sext i32 %i.0 to i64, !dbg !229
  %arrayidx1 = getelementptr inbounds i32, ptr %values, i64 %idxprom, !dbg !229
  %1 = load i32, ptr %arrayidx1, align 4, !dbg !229
  %cmp2 = icmp sgt i32 %1, %best.0, !dbg !232
  br i1 %cmp2, label %cond.true, label %cond.false, !dbg !229

cond.true:                                        ; preds = %for.body
  %idxprom3 = sext i32 %i.0 to i64, !dbg !233
  %arrayidx4 = getelementptr inbounds i32, ptr %values, i64 %idxprom3, !dbg !233
  %2 = load i32, ptr %arrayidx4, align 4, !dbg !233
  br label %cond.end, !dbg !229

cond.false:                                       ; preds = %for.body
  br label %cond.end, !dbg !229

cond.end:                                         ; preds = %cond.false, %cond.true
  %cond = phi i32 [ %2, %cond.true ], [ %best.0, %cond.false ], !dbg !229
    #dbg_value(i32 %cond, !220, !DIExpression(), !217)
  %tobool = icmp ne i32 %cond, 0, !dbg !234
  br i1 %tobool, label %if.then, label %if.end, !dbg !234

if.then:                                          ; preds = %cond.end
  %idxprom5 = sext i32 %i.0 to i64, !dbg !235
  %arrayidx6 = getelementptr inbounds i32, ptr %values, i64 %idxprom5, !dbg !235
  %3 = load i32, ptr %arrayidx6, align 4, !dbg !235
  %cmp7 = icmp eq i32 %cond, %3, !dbg !237
  %conv = zext i1 %cmp7 to i32, !dbg !237
  br label %if.end, !dbg !238

if.end:                                           ; preds = %if.then, %cond.end
  br label %for.inc, !dbg !239

for.inc:                                          ; preds = %if.end
  %inc = add nsw i32 %i.0, 1, !dbg !240
    #dbg_value(i32 %inc, !221, !DIExpression(), !223)
  br label %for.cond, !dbg !241, !llvm.loop !242

for.end:                                          ; preds = %for.cond
  ret i32 %best.0, !dbg !244
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @bump(i32 noundef %i) #0 !dbg !245 {
entry:
    #dbg_value(i32 %i, !246, !DIExpression(), !247)
  %inc = add nsw i32 %i, 1, !dbg !248
    #dbg_value(i32 %inc, !246, !DIExpression(), !247)
  %add = add nsw i32 %i, 1, !dbg !249
    #dbg_value(i32 %add, !246, !DIExpression(), !247)
  %cmp = icmp slt i32 %add, %add, !dbg !250
  br i1 %cmp, label %cond.true, label %cond.false, !dbg !251

cond.true:                                        ; preds = %entry
  br label %cond.end, !dbg !251

cond.false:                                       ; preds = %entry
  br label %cond.end, !dbg !251

cond.end:                                         ; preds = %cond.false, %cond.true
  %cond = phi i32 [ 0, %cond.true ], [ %add, %cond.false ], !dbg !251
  ret i32 %cond, !dbg !252
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @main() #0 !dbg !253 {
entry:
  %values = alloca [6 x i32], align 16
    #dbg_declare(ptr %values, !254, !DIExpression(), !258)
  call void @llvm.memcpy.p0.p0.i64(ptr align 16 %values, ptr align 16 @__const.main.values, i64 24, i1 false), !dbg !258
  %call = call i32 @sum_to(i32 noundef 10), !dbg !259
  %conv = sext i32 %call to i64, !dbg !259
  call void @print_total(i64 noundef %conv, double noundef 2.500000e+00), !dbg !260
  %arraydecay = getelementptr inbounds [6 x i32], ptr %values, i64 0, i64 0, !dbg !261
  %call1 = call i32 @first_positive(ptr noundef %arraydecay, i32 noundef 6), !dbg !262
  %arraydecay2 = getelementptr inbounds [6 x i32], ptr %values, i64 0, i64 0, !dbg !263
  %call3 = call i32 @max_of(ptr noundef %arraydecay2, i32 noundef 6), !dbg !264
  %add = add nsw i32 %call1, %call3, !dbg !265
  %arraydecay4 = getelementptr inbounds [6 x i32], ptr %values, i64 0, i64 0, !dbg !266
  %call5 = call i32 @scaled_sum(ptr noundef %arraydecay4, i32 noundef 6), !dbg !267
  %add6 = add nsw i32 %add, %call5, !dbg !268
  %arrayidx = getelementptr inbounds [6 x i32], ptr %values, i64 0, i64 5, !dbg !269
  %0 = load i32, ptr %arrayidx, align 4, !dbg !269
  %call7 = call i32 @clamp(i32 noundef %0), !dbg !270
  %add8 = add nsw i32 %add6, %call7, !dbg !271
  %call9 = call i32 @count_set_bits(i32 noundef 255), !dbg !272
  %add10 = add nsw i32 %add8, %call9, !dbg !273
  %call11 = call i32 @is_same(i32 noundef 1), !dbg !274
  %add12 = add nsw i32 %add10, %call11, !dbg !275
  %call13 = call zeroext i8 @small_constant(), !dbg !276
  %conv14 = zext i8 %call13 to i32, !dbg !276
  %add15 = add nsw i32 %add12, %conv14, !dbg !277
  %call16 = call i64 @wide_shift(i32 noundef 1), !dbg !278
  %conv17 = trunc i64 %call16 to i32, !dbg !279
  %add18 = add nsw i32 %add15, %conv17, !dbg !280
  %call19 = call i32 @skip_empty(i32 noundef 3), !dbg !281
  %add20 = add nsw i32 %add18, %call19, !dbg !282
  %call21 = call i32 @truncated_half(), !dbg !283
  %add22 = add nsw i32 %add20, %call21, !dbg !284
  %call23 = call i32 @last_of_four(), !dbg !285
  %add24 = add nsw i32 %add22, %call23, !dbg !286
  %call25 = call i32 @not_equal(i32 noundef 1, i32 noundef 2), !dbg !287
  %add26 = add nsw i32 %add24, %call25, !dbg !288
  %arraydecay27 = getelementptr inbounds [6 x i32], ptr %values, i64 0, i64 0, !dbg !289
  %call28 = call i32 @array_size(ptr noundef %arraydecay27), !dbg !290
  %add29 = add nsw i32 %add26, %call28, !dbg !291
  %call30 = call i32 @bump(i32 noundef 2), !dbg !292
  %add31 = add nsw i32 %add29, %call30, !dbg !293
  ret i32 %add31, !dbg !294
}

attributes #0 = { noinline nounwind uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

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
!57 = !DILocation(line: 17, column: 15, scope: !58)
!58 = distinct !DILexicalBlock(scope: !55, file: !2, line: 16, column: 37)
!59 = !DILocation(line: 18, column: 15, scope: !58)
!60 = !DILocation(line: 19, column: 5, scope: !58)
!61 = !DILocation(line: 16, column: 33, scope: !55)
!62 = !DILocation(line: 16, column: 5, scope: !55)
!63 = distinct !{!63, !56, !64, !41}
!64 = !DILocation(line: 19, column: 5, scope: !50)
!65 = !DILocation(line: 20, column: 5, scope: !43)
!66 = distinct !DISubprogram(name: "is_same", scope: !2, file: !2, line: 23, type: !44, scopeLine: 23, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!67 = !DILocalVariable(name: "value", arg: 1, scope: !66, file: !2, line: 23, type: !15)
!68 = !DILocation(line: 0, scope: !66)
!69 = !DILocation(line: 24, column: 18, scope: !66)
!70 = !DILocation(line: 24, column: 5, scope: !66)
!71 = distinct !DISubprogram(name: "small_constant", scope: !2, file: !2, line: 27, type: !72, scopeLine: 27, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!72 = !DISubroutineType(types: !73)
!73 = !{!74}
!74 = !DIBasicType(name: "unsigned char", size: 8, encoding: DW_ATE_unsigned_char)
!75 = !DILocalVariable(name: "byte", scope: !71, file: !2, line: 28, type: !74)
!76 = !DILocation(line: 0, scope: !71)
!77 = !DILocation(line: 29, column: 5, scope: !71)
!78 = distinct !DISubprogram(name: "wide_shift", scope: !2, file: !2, line: 32, type: !79, scopeLine: 32, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!79 = !DISubroutineType(types: !80)
!80 = !{!81, !15}
!81 = !DIBasicType(name: "long", size: 64, encoding: DW_ATE_signed)
!82 = !DILocalVariable(name: "value", arg: 1, scope: !78, file: !2, line: 32, type: !15)
!83 = !DILocation(line: 0, scope: !78)
!84 = !DILocation(line: 33, column: 18, scope: !78)
!85 = !DILocation(line: 33, column: 12, scope: !78)
!86 = !DILocation(line: 33, column: 5, scope: !78)
!87 = distinct !DISubprogram(name: "first_positive", scope: !2, file: !2, line: 36, type: !88, scopeLine: 36, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!88 = !DISubroutineType(types: !89)
!89 = !{!15, !90, !15}
!90 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !91, size: 64)
!91 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !15)
!92 = !DILocalVariable(name: "values", arg: 1, scope: !87, file: !2, line: 36, type: !90)
!93 = !DILocation(line: 0, scope: !87)
!94 = !DILocalVariable(name: "count", arg: 2, scope: !87, file: !2, line: 36, type: !15)
!95 = !DILocalVariable(name: "i", scope: !96, file: !2, line: 38, type: !15)
!96 = distinct !DILexicalBlock(scope: !87, file: !2, line: 38, column: 5)
!97 = !DILocation(line: 0, scope: !96)
!98 = !DILocation(line: 38, column: 10, scope: !96)
!99 = !DILocation(line: 38, scope: !96)
!100 = !DILocation(line: 38, column: 23, scope: !101)
!101 = distinct !DILexicalBlock(scope: !96, file: !2, line: 38, column: 5)
!102 = !DILocation(line: 38, column: 5, scope: !96)
!103 = !DILocation(line: 39, column: 21, scope: !104)
!104 = distinct !DILexicalBlock(scope: !105, file: !2, line: 39, column: 13)
!105 = distinct !DILexicalBlock(scope: !101, file: !2, line: 38, column: 37)
!106 = !DILocation(line: 39, column: 31, scope: !104)
!107 = !DILocalVariable(name: "found", scope: !87, file: !2, line: 37, type: !15)
!108 = !DILocation(line: 39, column: 19, scope: !104)
!109 = !DILocation(line: 40, column: 20, scope: !110)
!110 = distinct !DILexicalBlock(scope: !104, file: !2, line: 39, column: 36)
!111 = !DILocation(line: 40, column: 13, scope: !110)
!112 = !DILocation(line: 42, column: 5, scope: !105)
!113 = !DILocation(line: 38, column: 33, scope: !101)
!114 = !DILocation(line: 38, column: 5, scope: !101)
!115 = distinct !{!115, !102, !116, !41}
!116 = !DILocation(line: 42, column: 5, scope: !96)
!117 = !DILocation(line: 43, column: 5, scope: !87)
!118 = !DILocation(line: 44, column: 1, scope: !87)
!119 = distinct !DISubprogram(name: "skip_empty", scope: !2, file: !2, line: 46, type: !44, scopeLine: 46, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!120 = !DILocalVariable(name: "value", arg: 1, scope: !119, file: !2, line: 46, type: !15)
!121 = !DILocation(line: 0, scope: !119)
!122 = !DILocation(line: 47, column: 15, scope: !123)
!123 = distinct !DILexicalBlock(scope: !119, file: !2, line: 47, column: 9)
!124 = !DILocation(line: 48, column: 5, scope: !119)
!125 = distinct !DISubprogram(name: "truncated_half", scope: !2, file: !2, line: 51, type: !126, scopeLine: 51, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!126 = !DISubroutineType(types: !14)
!127 = !DILocalVariable(name: "half", scope: !125, file: !2, line: 52, type: !15)
!128 = !DILocation(line: 0, scope: !125)
!129 = !DILocation(line: 53, column: 5, scope: !125)
!130 = distinct !DISubprogram(name: "last_of_four", scope: !2, file: !2, line: 56, type: !126, scopeLine: 56, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!131 = !DILocalVariable(name: "four", scope: !130, file: !2, line: 57, type: !132)
!132 = !DICompositeType(tag: DW_TAG_array_type, baseType: !15, size: 128, elements: !133)
!133 = !{!134}
!134 = !DISubrange(count: 4)
!135 = !DILocation(line: 57, column: 9, scope: !130)
!136 = !DILocation(line: 58, column: 12, scope: !130)
!137 = !DILocation(line: 58, column: 5, scope: !130)
!138 = distinct !DISubprogram(name: "not_equal", scope: !2, file: !2, line: 61, type: !139, scopeLine: 61, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!139 = !DISubroutineType(types: !140)
!140 = !{!15, !15, !15}
!141 = !DILocalVariable(name: "a", arg: 1, scope: !138, file: !2, line: 61, type: !15)
!142 = !DILocation(line: 0, scope: !138)
!143 = !DILocalVariable(name: "b", arg: 2, scope: !138, file: !2, line: 61, type: !15)
!144 = !DILocation(line: 62, column: 9, scope: !145)
!145 = distinct !DILexicalBlock(scope: !138, file: !2, line: 62, column: 9)
!146 = !DILocation(line: 62, column: 12, scope: !145)
!147 = !DILocation(line: 63, column: 9, scope: !148)
!148 = distinct !DILexicalBlock(scope: !145, file: !2, line: 62, column: 18)
!149 = !DILocation(line: 65, column: 5, scope: !138)
!150 = !DILocation(line: 66, column: 1, scope: !138)
!151 = distinct !DISubprogram(name: "array_size", scope: !2, file: !2, line: 68, type: !152, scopeLine: 68, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!152 = !DISubroutineType(types: !153)
!153 = !{!15, !154}
!154 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !15, size: 64)
!155 = !DILocalVariable(name: "values", arg: 1, scope: !151, file: !2, line: 68, type: !154)
!156 = !DILocation(line: 0, scope: !151)
!157 = !DILocation(line: 69, column: 5, scope: !151)
!158 = distinct !DISubprogram(name: "print_total", scope: !2, file: !2, line: 72, type: !159, scopeLine: 72, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!159 = !DISubroutineType(types: !160)
!160 = !{null, !81, !161}
!161 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!162 = !DILocalVariable(name: "total", arg: 1, scope: !158, file: !2, line: 72, type: !81)
!163 = !DILocation(line: 0, scope: !158)
!164 = !DILocalVariable(name: "mean", arg: 2, scope: !158, file: !2, line: 72, type: !161)
!165 = !DILocation(line: 73, column: 5, scope: !158)
!166 = !DILocation(line: 74, column: 5, scope: !158)
!167 = !DILocation(line: 75, column: 1, scope: !158)
!168 = distinct !DISubprogram(name: "scaled_sum", scope: !2, file: !2, line: 77, type: !88, scopeLine: 77, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!169 = !DILocalVariable(name: "values", arg: 1, scope: !168, file: !2, line: 77, type: !90)
!170 = !DILocation(line: 0, scope: !168)
!171 = !DILocalVariable(name: "count", arg: 2, scope: !168, file: !2, line: 77, type: !15)
!172 = !DILocalVariable(name: "total", scope: !168, file: !2, line: 78, type: !15)
!173 = !DILocalVariable(name: "i", scope: !174, file: !2, line: 79, type: !15)
!174 = distinct !DILexicalBlock(scope: !168, file: !2, line: 79, column: 5)
!175 = !DILocation(line: 0, scope: !174)
!176 = !DILocation(line: 79, column: 10, scope: !174)
!177 = !DILocation(line: 79, scope: !174)
!178 = !DILocation(line: 79, column: 23, scope: !179)
!179 = distinct !DILexicalBlock(scope: !174, file: !2, line: 79, column: 5)
!180 = !DILocation(line: 79, column: 5, scope: !174)
!181 = !DILocation(line: 80, column: 29, scope: !182)
!182 = distinct !DILexicalBlock(scope: !183, file: !2, line: 80, column: 13)
!183 = distinct !DILexicalBlock(scope: !179, file: !2, line: 79, column: 37)
!184 = !DILocation(line: 80, column: 39, scope: !182)
!185 = !DILocation(line: 80, column: 27, scope: !182)
!186 = !DILocation(line: 80, column: 19, scope: !182)
!187 = !DILocation(line: 81, column: 19, scope: !188)
!188 = distinct !DILexicalBlock(scope: !182, file: !2, line: 80, column: 44)
!189 = !DILocation(line: 82, column: 9, scope: !188)
!190 = !DILocation(line: 83, column: 5, scope: !183)
!191 = !DILocation(line: 79, column: 33, scope: !179)
!192 = !DILocation(line: 79, column: 5, scope: !179)
!193 = distinct !{!193, !180, !194, !41}
!194 = !DILocation(line: 83, column: 5, scope: !174)
!195 = !DILocation(line: 84, column: 5, scope: !168)
!196 = distinct !DISubprogram(name: "clamp", scope: !2, file: !2, line: 87, type: !44, scopeLine: 87, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!197 = !DILocalVariable(name: "value", arg: 1, scope: !196, file: !2, line: 87, type: !15)
!198 = !DILocation(line: 0, scope: !196)
!199 = !DILocalVariable(name: "low", scope: !196, file: !2, line: 88, type: !4)
!200 = !DILocalVariable(name: "high", scope: !196, file: !2, line: 89, type: !4)
!201 = !DILocation(line: 90, column: 17, scope: !202)
!202 = distinct !DILexicalBlock(scope: !196, file: !2, line: 90, column: 9)
!203 = !DILocation(line: 90, column: 15, scope: !202)
!204 = !DILocation(line: 91, column: 16, scope: !205)
!205 = distinct !DILexicalBlock(scope: !202, file: !2, line: 90, column: 22)
!206 = !DILocation(line: 91, column: 9, scope: !205)
!207 = !DILocation(line: 93, column: 17, scope: !208)
!208 = distinct !DILexicalBlock(scope: !196, file: !2, line: 93, column: 9)
!209 = !DILocation(line: 93, column: 15, scope: !208)
!210 = !DILocation(line: 94, column: 16, scope: !211)
!211 = distinct !DILexicalBlock(scope: !208, file: !2, line: 93, column: 23)
!212 = !DILocation(line: 94, column: 9, scope: !211)
!213 = !DILocation(line: 96, column: 5, scope: !196)
!214 = !DILocation(line: 97, column: 1, scope: !196)
!215 = distinct !DISubprogram(name: "max_of", scope: !2, file: !2, line: 99, type: !88, scopeLine: 99, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!216 = !DILocalVariable(name: "values", arg: 1, scope: !215, file: !2, line: 99, type: !90)
!217 = !DILocation(line: 0, scope: !215)
!218 = !DILocalVariable(name: "count", arg: 2, scope: !215, file: !2, line: 99, type: !15)
!219 = !DILocation(line: 100, column: 16, scope: !215)
!220 = !DILocalVariable(name: "best", scope: !215, file: !2, line: 100, type: !15)
!221 = !DILocalVariable(name: "i", scope: !222, file: !2, line: 101, type: !15)
!222 = distinct !DILexicalBlock(scope: !215, file: !2, line: 101, column: 5)
!223 = !DILocation(line: 0, scope: !222)
!224 = !DILocation(line: 101, column: 10, scope: !222)
!225 = !DILocation(line: 101, scope: !222)
!226 = !DILocation(line: 101, column: 23, scope: !227)
!227 = distinct !DILexicalBlock(scope: !222, file: !2, line: 101, column: 5)
!228 = !DILocation(line: 101, column: 5, scope: !222)
!229 = !DILocation(line: 102, column: 20, scope: !230)
!230 = distinct !DILexicalBlock(scope: !231, file: !2, line: 102, column: 13)
!231 = distinct !DILexicalBlock(scope: !227, file: !2, line: 101, column: 37)
!232 = !DILocation(line: 102, column: 30, scope: !230)
!233 = !DILocation(line: 102, column: 39, scope: !230)
!234 = !DILocation(line: 102, column: 18, scope: !230)
!235 = !DILocation(line: 103, column: 21, scope: !236)
!236 = distinct !DILexicalBlock(scope: !230, file: !2, line: 102, column: 57)
!237 = !DILocation(line: 103, column: 18, scope: !236)
!238 = !DILocation(line: 104, column: 9, scope: !236)
!239 = !DILocation(line: 105, column: 5, scope: !231)
!240 = !DILocation(line: 101, column: 33, scope: !227)
!241 = !DILocation(line: 101, column: 5, scope: !227)
!242 = distinct !{!242, !228, !243, !41}
!243 = !DILocation(line: 105, column: 5, scope: !222)
!244 = !DILocation(line: 106, column: 5, scope: !215)
!245 = distinct !DISubprogram(name: "bump", scope: !2, file: !2, line: 109, type: !44, scopeLine: 109, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!246 = !DILocalVariable(name: "i", arg: 1, scope: !245, file: !2, line: 109, type: !15)
!247 = !DILocation(line: 0, scope: !245)
!248 = !DILocation(line: 110, column: 10, scope: !245)
!249 = !DILocation(line: 110, column: 13, scope: !245)
!250 = !DILocation(line: 111, column: 14, scope: !245)
!251 = !DILocation(line: 111, column: 12, scope: !245)
!252 = !DILocation(line: 111, column: 5, scope: !245)
!253 = distinct !DISubprogram(name: "main", scope: !2, file: !2, line: 114, type: !126, scopeLine: 114, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!254 = !DILocalVariable(name: "values", scope: !253, file: !2, line: 115, type: !255)
!255 = !DICompositeType(tag: DW_TAG_array_type, baseType: !15, size: 192, elements: !256)
!256 = !{!257}
!257 = !DISubrange(count: 6)
!258 = !DILocation(line: 115, column: 9, scope: !253)
!259 = !DILocation(line: 116, column: 17, scope: !253)
!260 = !DILocation(line: 116, column: 5, scope: !253)
!261 = !DILocation(line: 117, column: 27, scope: !253)
!262 = !DILocation(line: 117, column: 12, scope: !253)
!263 = !DILocation(line: 117, column: 47, scope: !253)
!264 = !DILocation(line: 117, column: 40, scope: !253)
!265 = !DILocation(line: 117, column: 38, scope: !253)
!266 = !DILocation(line: 117, column: 71, scope: !253)
!267 = !DILocation(line: 117, column: 60, scope: !253)
!268 = !DILocation(line: 117, column: 58, scope: !253)
!269 = !DILocation(line: 117, column: 90, scope: !253)
!270 = !DILocation(line: 117, column: 84, scope: !253)
!271 = !DILocation(line: 117, column: 82, scope: !253)
!272 = !DILocation(line: 118, column: 11, scope: !253)
!273 = !DILocation(line: 118, column: 9, scope: !253)
!274 = !DILocation(line: 118, column: 34, scope: !253)
!275 = !DILocation(line: 118, column: 32, scope: !253)
!276 = !DILocation(line: 118, column: 47, scope: !253)
!277 = !DILocation(line: 118, column: 45, scope: !253)
!278 = !DILocation(line: 118, column: 71, scope: !253)
!279 = !DILocation(line: 118, column: 66, scope: !253)
!280 = !DILocation(line: 118, column: 64, scope: !253)
!281 = !DILocation(line: 118, column: 87, scope: !253)
!282 = !DILocation(line: 118, column: 85, scope: !253)
!283 = !DILocation(line: 119, column: 11, scope: !253)
!284 = !DILocation(line: 119, column: 9, scope: !253)
!285 = !DILocation(line: 119, column: 30, scope: !253)
!286 = !DILocation(line: 119, column: 28, scope: !253)
!287 = !DILocation(line: 119, column: 47, scope: !253)
!288 = !DILocation(line: 119, column: 45, scope: !253)
!289 = !DILocation(line: 119, column: 76, scope: !253)
!290 = !DILocation(line: 119, column: 65, scope: !253)
!291 = !DILocation(line: 119, column: 63, scope: !253)
!292 = !DILocation(line: 119, column: 86, scope: !253)
!293 = !DILocation(line: 119, column: 84, scope: !253)
!294 = !DILocation(line: 117, column: 5, scope: !253)
