; ModuleID = '/workspace/user-programs/clang_warnings.c'
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
  %value.addr = alloca i32, align 4
  %count = alloca i32, align 4
  %bit = alloca i32, align 4
  store i32 %value, ptr %value.addr, align 4
    #dbg_declare(ptr %value.addr, !30, !DIExpression(), !31)
    #dbg_declare(ptr %count, !32, !DIExpression(), !33)
  store i32 0, ptr %count, align 4, !dbg !33
    #dbg_declare(ptr %bit, !34, !DIExpression(), !35)
  br label %while.cond, !dbg !36

while.cond:                                       ; preds = %while.body, %entry
  %0 = load i32, ptr %value.addr, align 4, !dbg !37
  %and = and i32 %0, 1, !dbg !38
  store i32 %and, ptr %bit, align 4, !dbg !39
  %tobool = icmp ne i32 %and, 0, !dbg !36
  br i1 %tobool, label %while.body, label %while.end, !dbg !36

while.body:                                       ; preds = %while.cond
  %1 = load i32, ptr %bit, align 4, !dbg !40
  %2 = load i32, ptr %count, align 4, !dbg !42
  %add = add i32 %2, %1, !dbg !42
  store i32 %add, ptr %count, align 4, !dbg !42
  %3 = load i32, ptr %value.addr, align 4, !dbg !43
  %shr = lshr i32 %3, 1, !dbg !43
  store i32 %shr, ptr %value.addr, align 4, !dbg !43
  br label %while.cond, !dbg !36, !llvm.loop !44

while.end:                                        ; preds = %while.cond
  %4 = load i32, ptr %count, align 4, !dbg !47
  ret i32 %4, !dbg !48
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @sum_to(i32 noundef %limit) #0 !dbg !49 {
entry:
  %limit.addr = alloca i32, align 4
  %total = alloca i32, align 4
  %i = alloca i32, align 4
  store i32 %limit, ptr %limit.addr, align 4
    #dbg_declare(ptr %limit.addr, !52, !DIExpression(), !53)
    #dbg_declare(ptr %total, !54, !DIExpression(), !55)
  store i32 0, ptr %total, align 4, !dbg !55
    #dbg_declare(ptr %i, !56, !DIExpression(), !58)
  store i32 0, ptr %i, align 4, !dbg !58
  br label %for.cond, !dbg !59

for.cond:                                         ; preds = %for.inc, %entry
  %0 = load i32, ptr %i, align 4, !dbg !60
  %1 = load i32, ptr %limit.addr, align 4, !dbg !62
  %cmp = icmp slt i32 %0, %1, !dbg !63
  br i1 %cmp, label %for.body, label %for.end, !dbg !64

for.body:                                         ; preds = %for.cond
  %2 = load i32, ptr %total, align 4, !dbg !65
  %3 = load i32, ptr %i, align 4, !dbg !67
  %add = add nsw i32 %2, %3, !dbg !68
  %4 = load i32, ptr %i, align 4, !dbg !69
  %5 = load i32, ptr %total, align 4, !dbg !70
  %add1 = add nsw i32 %5, %4, !dbg !70
  store i32 %add1, ptr %total, align 4, !dbg !70
  br label %for.inc, !dbg !71

for.inc:                                          ; preds = %for.body
  %6 = load i32, ptr %i, align 4, !dbg !72
  %inc = add nsw i32 %6, 1, !dbg !72
  store i32 %inc, ptr %i, align 4, !dbg !72
  br label %for.cond, !dbg !73, !llvm.loop !74

for.end:                                          ; preds = %for.cond
  %7 = load i32, ptr %total, align 4, !dbg !76
  ret i32 %7, !dbg !77
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @is_same(i32 noundef %value) #0 !dbg !78 {
entry:
  %value.addr = alloca i32, align 4
  store i32 %value, ptr %value.addr, align 4
    #dbg_declare(ptr %value.addr, !79, !DIExpression(), !80)
  %0 = load i32, ptr %value.addr, align 4, !dbg !81
  %1 = load i32, ptr %value.addr, align 4, !dbg !82
  %cmp = icmp eq i32 %0, %1, !dbg !83
  %conv = zext i1 %cmp to i32, !dbg !83
  ret i32 %conv, !dbg !84
}

; Function Attrs: noinline nounwind uwtable
define dso_local zeroext i8 @small_constant() #0 !dbg !85 {
entry:
  %byte = alloca i8, align 1
    #dbg_declare(ptr %byte, !89, !DIExpression(), !90)
  store i8 44, ptr %byte, align 1, !dbg !90
  %0 = load i8, ptr %byte, align 1, !dbg !91
  ret i8 %0, !dbg !92
}

; Function Attrs: noinline nounwind uwtable
define dso_local i64 @wide_shift(i32 noundef %value) #0 !dbg !93 {
entry:
  %value.addr = alloca i32, align 4
  store i32 %value, ptr %value.addr, align 4
    #dbg_declare(ptr %value.addr, !97, !DIExpression(), !98)
  %0 = load i32, ptr %value.addr, align 4, !dbg !99
  %shl = shl i32 %0, 40, !dbg !100
  %conv = sext i32 %shl to i64, !dbg !99
  ret i64 %conv, !dbg !101
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @first_positive(ptr noundef %values, i32 noundef %count) #0 !dbg !102 {
entry:
  %retval = alloca i32, align 4
  %values.addr = alloca ptr, align 8
  %count.addr = alloca i32, align 4
  %found = alloca i32, align 4
  %i = alloca i32, align 4
  store ptr %values, ptr %values.addr, align 8
    #dbg_declare(ptr %values.addr, !107, !DIExpression(), !108)
  store i32 %count, ptr %count.addr, align 4
    #dbg_declare(ptr %count.addr, !109, !DIExpression(), !110)
    #dbg_declare(ptr %found, !111, !DIExpression(), !112)
    #dbg_declare(ptr %i, !113, !DIExpression(), !115)
  store i32 0, ptr %i, align 4, !dbg !115
  br label %for.cond, !dbg !116

for.cond:                                         ; preds = %for.inc, %entry
  %0 = load i32, ptr %i, align 4, !dbg !117
  %1 = load i32, ptr %count.addr, align 4, !dbg !119
  %cmp = icmp slt i32 %0, %1, !dbg !120
  br i1 %cmp, label %for.body, label %for.end, !dbg !121

for.body:                                         ; preds = %for.cond
  %2 = load ptr, ptr %values.addr, align 8, !dbg !122
  %3 = load i32, ptr %i, align 4, !dbg !125
  %idxprom = sext i32 %3 to i64, !dbg !122
  %arrayidx = getelementptr inbounds i32, ptr %2, i64 %idxprom, !dbg !122
  %4 = load i32, ptr %arrayidx, align 4, !dbg !122
  %cmp1 = icmp sgt i32 %4, 0, !dbg !126
  %conv = zext i1 %cmp1 to i32, !dbg !126
  store i32 %conv, ptr %found, align 4, !dbg !127
  br i1 %cmp1, label %if.then, label %if.end, !dbg !127

if.then:                                          ; preds = %for.body
  %5 = load ptr, ptr %values.addr, align 8, !dbg !128
  %6 = load i32, ptr %i, align 4, !dbg !130
  %idxprom2 = sext i32 %6 to i64, !dbg !128
  %arrayidx3 = getelementptr inbounds i32, ptr %5, i64 %idxprom2, !dbg !128
  %7 = load i32, ptr %arrayidx3, align 4, !dbg !128
  store i32 %7, ptr %retval, align 4, !dbg !131
  br label %return, !dbg !131

if.end:                                           ; preds = %for.body
  br label %for.inc, !dbg !132

for.inc:                                          ; preds = %if.end
  %8 = load i32, ptr %i, align 4, !dbg !133
  %inc = add nsw i32 %8, 1, !dbg !133
  store i32 %inc, ptr %i, align 4, !dbg !133
  br label %for.cond, !dbg !134, !llvm.loop !135

for.end:                                          ; preds = %for.cond
  store i32 0, ptr %retval, align 4, !dbg !137
  br label %return, !dbg !137

return:                                           ; preds = %for.end, %if.then
  %9 = load i32, ptr %retval, align 4, !dbg !138
  ret i32 %9, !dbg !138
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @skip_empty(i32 noundef %value) #0 !dbg !139 {
entry:
  %value.addr = alloca i32, align 4
  store i32 %value, ptr %value.addr, align 4
    #dbg_declare(ptr %value.addr, !140, !DIExpression(), !141)
  %0 = load i32, ptr %value.addr, align 4, !dbg !142
  %cmp = icmp sgt i32 %0, 10, !dbg !144
  br i1 %cmp, label %if.then, label %if.end, !dbg !144

if.then:                                          ; preds = %entry
  br label %if.end, !dbg !144

if.end:                                           ; preds = %if.then, %entry
  %1 = load i32, ptr %value.addr, align 4, !dbg !145
  ret i32 %1, !dbg !146
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @truncated_half() #0 !dbg !147 {
entry:
  %half = alloca i32, align 4
    #dbg_declare(ptr %half, !149, !DIExpression(), !150)
  store i32 2, ptr %half, align 4, !dbg !150
  %0 = load i32, ptr %half, align 4, !dbg !151
  ret i32 %0, !dbg !152
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @last_of_four() #0 !dbg !153 {
entry:
  %four = alloca [4 x i32], align 16
    #dbg_declare(ptr %four, !154, !DIExpression(), !158)
  call void @llvm.memcpy.p0.p0.i64(ptr align 16 %four, ptr align 16 @__const.last_of_four.four, i64 16, i1 false), !dbg !158
  %arrayidx = getelementptr inbounds [4 x i32], ptr %four, i64 0, i64 4, !dbg !159
  %0 = load i32, ptr %arrayidx, align 16, !dbg !159
  ret i32 %0, !dbg !160
}

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @not_equal(i32 noundef %a, i32 noundef %b) #0 !dbg !161 {
entry:
  %retval = alloca i32, align 4
  %a.addr = alloca i32, align 4
  %b.addr = alloca i32, align 4
  store i32 %a, ptr %a.addr, align 4
    #dbg_declare(ptr %a.addr, !164, !DIExpression(), !165)
  store i32 %b, ptr %b.addr, align 4
    #dbg_declare(ptr %b.addr, !166, !DIExpression(), !167)
  %0 = load i32, ptr %a.addr, align 4, !dbg !168
  %tobool = icmp ne i32 %0, 0, !dbg !170
  %lnot = xor i1 %tobool, true, !dbg !170
  %lnot.ext = zext i1 %lnot to i32, !dbg !170
  %1 = load i32, ptr %b.addr, align 4, !dbg !171
  %cmp = icmp eq i32 %lnot.ext, %1, !dbg !172
  br i1 %cmp, label %if.then, label %if.end, !dbg !172

if.then:                                          ; preds = %entry
  store i32 1, ptr %retval, align 4, !dbg !173
  br label %return, !dbg !173

if.end:                                           ; preds = %entry
  store i32 0, ptr %retval, align 4, !dbg !175
  br label %return, !dbg !175

return:                                           ; preds = %if.end, %if.then
  %2 = load i32, ptr %retval, align 4, !dbg !176
  ret i32 %2, !dbg !176
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @array_size(ptr noundef %values) #0 !dbg !177 {
entry:
  %values.addr = alloca ptr, align 8
  store ptr %values, ptr %values.addr, align 8
    #dbg_declare(ptr %values.addr, !181, !DIExpression(), !182)
  ret i32 2, !dbg !183
}

; Function Attrs: noinline nounwind uwtable
define dso_local void @print_total(i64 noundef %total, double noundef %mean) #0 !dbg !184 {
entry:
  %total.addr = alloca i64, align 8
  %mean.addr = alloca double, align 8
  store i64 %total, ptr %total.addr, align 8
    #dbg_declare(ptr %total.addr, !188, !DIExpression(), !189)
  store double %mean, ptr %mean.addr, align 8
    #dbg_declare(ptr %mean.addr, !190, !DIExpression(), !191)
  %0 = load i64, ptr %total.addr, align 8, !dbg !192
  %call = call i32 (ptr, ...) @printf(ptr noundef @.str, i64 noundef %0), !dbg !193
  %1 = load double, ptr %mean.addr, align 8, !dbg !194
  %call1 = call i32 (ptr, ...) @printf(ptr noundef @.str.1, double noundef %1), !dbg !195
  ret void, !dbg !196
}

declare i32 @printf(ptr noundef, ...) #2

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @scaled_sum(ptr noundef %values, i32 noundef %count) #0 !dbg !197 {
entry:
  %values.addr = alloca ptr, align 8
  %count.addr = alloca i32, align 4
  %total = alloca i32, align 4
  %i = alloca i32, align 4
  store ptr %values, ptr %values.addr, align 8
    #dbg_declare(ptr %values.addr, !198, !DIExpression(), !199)
  store i32 %count, ptr %count.addr, align 4
    #dbg_declare(ptr %count.addr, !200, !DIExpression(), !201)
    #dbg_declare(ptr %total, !202, !DIExpression(), !203)
  store i32 0, ptr %total, align 4, !dbg !203
    #dbg_declare(ptr %i, !204, !DIExpression(), !206)
  store i32 0, ptr %i, align 4, !dbg !206
  br label %for.cond, !dbg !207

for.cond:                                         ; preds = %for.inc, %entry
  %0 = load i32, ptr %i, align 4, !dbg !208
  %1 = load i32, ptr %count.addr, align 4, !dbg !210
  %cmp = icmp slt i32 %0, %1, !dbg !211
  br i1 %cmp, label %for.body, label %for.end, !dbg !212

for.body:                                         ; preds = %for.cond
  %2 = load i32, ptr %total, align 4, !dbg !213
  %3 = load ptr, ptr %values.addr, align 8, !dbg !216
  %4 = load i32, ptr %i, align 4, !dbg !217
  %idxprom = sext i32 %4 to i64, !dbg !216
  %arrayidx = getelementptr inbounds i32, ptr %3, i64 %idxprom, !dbg !216
  %5 = load i32, ptr %arrayidx, align 4, !dbg !216
  %mul = mul nsw i32 %5, 2, !dbg !218
  %add = add nsw i32 %2, %mul, !dbg !219
  store i32 %add, ptr %total, align 4, !dbg !220
  %tobool = icmp ne i32 %add, 0, !dbg !220
  br i1 %tobool, label %if.then, label %if.end, !dbg !220

if.then:                                          ; preds = %for.body
  %6 = load i32, ptr %total, align 4, !dbg !221
  %cmp1 = icmp eq i32 %6, 0, !dbg !223
  %conv = zext i1 %cmp1 to i32, !dbg !223
  br label %if.end, !dbg !224

if.end:                                           ; preds = %if.then, %for.body
  br label %for.inc, !dbg !225

for.inc:                                          ; preds = %if.end
  %7 = load i32, ptr %i, align 4, !dbg !226
  %inc = add nsw i32 %7, 1, !dbg !226
  store i32 %inc, ptr %i, align 4, !dbg !226
  br label %for.cond, !dbg !227, !llvm.loop !228

for.end:                                          ; preds = %for.cond
  %8 = load i32, ptr %total, align 4, !dbg !230
  ret i32 %8, !dbg !231
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @clamp(i32 noundef %value) #0 !dbg !232 {
entry:
  %retval = alloca i32, align 4
  %value.addr = alloca i32, align 4
  %low = alloca i8, align 1
  %high = alloca i8, align 1
  store i32 %value, ptr %value.addr, align 4
    #dbg_declare(ptr %value.addr, !233, !DIExpression(), !234)
    #dbg_declare(ptr %low, !235, !DIExpression(), !236)
  store i8 56, ptr %low, align 1, !dbg !236
    #dbg_declare(ptr %high, !237, !DIExpression(), !238)
  store i8 -56, ptr %high, align 1, !dbg !238
  %0 = load i32, ptr %value.addr, align 4, !dbg !239
  %1 = load i8, ptr %low, align 1, !dbg !241
  %conv = sext i8 %1 to i32, !dbg !241
  %cmp = icmp slt i32 %0, %conv, !dbg !242
  br i1 %cmp, label %if.then, label %if.end, !dbg !242

if.then:                                          ; preds = %entry
  %2 = load i8, ptr %low, align 1, !dbg !243
  %conv2 = sext i8 %2 to i32, !dbg !243
  store i32 %conv2, ptr %retval, align 4, !dbg !245
  br label %return, !dbg !245

if.end:                                           ; preds = %entry
  %3 = load i32, ptr %value.addr, align 4, !dbg !246
  %4 = load i8, ptr %high, align 1, !dbg !248
  %conv3 = sext i8 %4 to i32, !dbg !248
  %cmp4 = icmp sgt i32 %3, %conv3, !dbg !249
  br i1 %cmp4, label %if.then6, label %if.end8, !dbg !249

if.then6:                                         ; preds = %if.end
  %5 = load i8, ptr %high, align 1, !dbg !250
  %conv7 = sext i8 %5 to i32, !dbg !250
  store i32 %conv7, ptr %retval, align 4, !dbg !252
  br label %return, !dbg !252

if.end8:                                          ; preds = %if.end
  %6 = load i32, ptr %value.addr, align 4, !dbg !253
  store i32 %6, ptr %retval, align 4, !dbg !254
  br label %return, !dbg !254

return:                                           ; preds = %if.end8, %if.then6, %if.then
  %7 = load i32, ptr %retval, align 4, !dbg !255
  ret i32 %7, !dbg !255
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @max_of(ptr noundef %values, i32 noundef %count) #0 !dbg !256 {
entry:
  %values.addr = alloca ptr, align 8
  %count.addr = alloca i32, align 4
  %best = alloca i32, align 4
  %i = alloca i32, align 4
  store ptr %values, ptr %values.addr, align 8
    #dbg_declare(ptr %values.addr, !257, !DIExpression(), !258)
  store i32 %count, ptr %count.addr, align 4
    #dbg_declare(ptr %count.addr, !259, !DIExpression(), !260)
    #dbg_declare(ptr %best, !261, !DIExpression(), !262)
  %0 = load ptr, ptr %values.addr, align 8, !dbg !263
  %arrayidx = getelementptr inbounds i32, ptr %0, i64 0, !dbg !263
  %1 = load i32, ptr %arrayidx, align 4, !dbg !263
  store i32 %1, ptr %best, align 4, !dbg !262
    #dbg_declare(ptr %i, !264, !DIExpression(), !266)
  store i32 1, ptr %i, align 4, !dbg !266
  br label %for.cond, !dbg !267

for.cond:                                         ; preds = %for.inc, %entry
  %2 = load i32, ptr %i, align 4, !dbg !268
  %3 = load i32, ptr %count.addr, align 4, !dbg !270
  %cmp = icmp slt i32 %2, %3, !dbg !271
  br i1 %cmp, label %for.body, label %for.end, !dbg !272

for.body:                                         ; preds = %for.cond
  %4 = load ptr, ptr %values.addr, align 8, !dbg !273
  %5 = load i32, ptr %i, align 4, !dbg !276
  %idxprom = sext i32 %5 to i64, !dbg !273
  %arrayidx1 = getelementptr inbounds i32, ptr %4, i64 %idxprom, !dbg !273
  %6 = load i32, ptr %arrayidx1, align 4, !dbg !273
  %7 = load i32, ptr %best, align 4, !dbg !277
  %cmp2 = icmp sgt i32 %6, %7, !dbg !278
  br i1 %cmp2, label %cond.true, label %cond.false, !dbg !273

cond.true:                                        ; preds = %for.body
  %8 = load ptr, ptr %values.addr, align 8, !dbg !279
  %9 = load i32, ptr %i, align 4, !dbg !280
  %idxprom3 = sext i32 %9 to i64, !dbg !279
  %arrayidx4 = getelementptr inbounds i32, ptr %8, i64 %idxprom3, !dbg !279
  %10 = load i32, ptr %arrayidx4, align 4, !dbg !279
  br label %cond.end, !dbg !273

cond.false:                                       ; preds = %for.body
  %11 = load i32, ptr %best, align 4, !dbg !281
  br label %cond.end, !dbg !273

cond.end:                                         ; preds = %cond.false, %cond.true
  %cond = phi i32 [ %10, %cond.true ], [ %11, %cond.false ], !dbg !273
  store i32 %cond, ptr %best, align 4, !dbg !282
  %tobool = icmp ne i32 %cond, 0, !dbg !282
  br i1 %tobool, label %if.then, label %if.end, !dbg !282

if.then:                                          ; preds = %cond.end
  %12 = load i32, ptr %best, align 4, !dbg !283
  %13 = load ptr, ptr %values.addr, align 8, !dbg !285
  %14 = load i32, ptr %i, align 4, !dbg !286
  %idxprom5 = sext i32 %14 to i64, !dbg !285
  %arrayidx6 = getelementptr inbounds i32, ptr %13, i64 %idxprom5, !dbg !285
  %15 = load i32, ptr %arrayidx6, align 4, !dbg !285
  %cmp7 = icmp eq i32 %12, %15, !dbg !287
  %conv = zext i1 %cmp7 to i32, !dbg !287
  br label %if.end, !dbg !288

if.end:                                           ; preds = %if.then, %cond.end
  br label %for.inc, !dbg !289

for.inc:                                          ; preds = %if.end
  %16 = load i32, ptr %i, align 4, !dbg !290
  %inc = add nsw i32 %16, 1, !dbg !290
  store i32 %inc, ptr %i, align 4, !dbg !290
  br label %for.cond, !dbg !291, !llvm.loop !292

for.end:                                          ; preds = %for.cond
  %17 = load i32, ptr %best, align 4, !dbg !294
  ret i32 %17, !dbg !295
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @bump(i32 noundef %i) #0 !dbg !296 {
entry:
  %i.addr = alloca i32, align 4
  store i32 %i, ptr %i.addr, align 4
    #dbg_declare(ptr %i.addr, !297, !DIExpression(), !298)
  %0 = load i32, ptr %i.addr, align 4, !dbg !299
  %inc = add nsw i32 %0, 1, !dbg !299
  store i32 %inc, ptr %i.addr, align 4, !dbg !299
  %add = add nsw i32 %0, 1, !dbg !300
  store i32 %add, ptr %i.addr, align 4, !dbg !301
  %1 = load i32, ptr %i.addr, align 4, !dbg !302
  %2 = load i32, ptr %i.addr, align 4, !dbg !303
  %cmp = icmp slt i32 %1, %2, !dbg !304
  br i1 %cmp, label %cond.true, label %cond.false, !dbg !302

cond.true:                                        ; preds = %entry
  br label %cond.end, !dbg !302

cond.false:                                       ; preds = %entry
  %3 = load i32, ptr %i.addr, align 4, !dbg !305
  br label %cond.end, !dbg !302

cond.end:                                         ; preds = %cond.false, %cond.true
  %cond = phi i32 [ 0, %cond.true ], [ %3, %cond.false ], !dbg !302
  ret i32 %cond, !dbg !306
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @main() #0 !dbg !307 {
entry:
  %retval = alloca i32, align 4
  %values = alloca [6 x i32], align 16
  store i32 0, ptr %retval, align 4
    #dbg_declare(ptr %values, !308, !DIExpression(), !312)
  call void @llvm.memcpy.p0.p0.i64(ptr align 16 %values, ptr align 16 @__const.main.values, i64 24, i1 false), !dbg !312
  %call = call i32 @sum_to(i32 noundef 10), !dbg !313
  %conv = sext i32 %call to i64, !dbg !313
  call void @print_total(i64 noundef %conv, double noundef 2.500000e+00), !dbg !314
  %arraydecay = getelementptr inbounds [6 x i32], ptr %values, i64 0, i64 0, !dbg !315
  %call1 = call i32 @first_positive(ptr noundef %arraydecay, i32 noundef 6), !dbg !316
  %arraydecay2 = getelementptr inbounds [6 x i32], ptr %values, i64 0, i64 0, !dbg !317
  %call3 = call i32 @max_of(ptr noundef %arraydecay2, i32 noundef 6), !dbg !318
  %add = add nsw i32 %call1, %call3, !dbg !319
  %arraydecay4 = getelementptr inbounds [6 x i32], ptr %values, i64 0, i64 0, !dbg !320
  %call5 = call i32 @scaled_sum(ptr noundef %arraydecay4, i32 noundef 6), !dbg !321
  %add6 = add nsw i32 %add, %call5, !dbg !322
  %arrayidx = getelementptr inbounds [6 x i32], ptr %values, i64 0, i64 5, !dbg !323
  %0 = load i32, ptr %arrayidx, align 4, !dbg !323
  %call7 = call i32 @clamp(i32 noundef %0), !dbg !324
  %add8 = add nsw i32 %add6, %call7, !dbg !325
  %call9 = call i32 @count_set_bits(i32 noundef 255), !dbg !326
  %add10 = add nsw i32 %add8, %call9, !dbg !327
  %call11 = call i32 @is_same(i32 noundef 1), !dbg !328
  %add12 = add nsw i32 %add10, %call11, !dbg !329
  %call13 = call zeroext i8 @small_constant(), !dbg !330
  %conv14 = zext i8 %call13 to i32, !dbg !330
  %add15 = add nsw i32 %add12, %conv14, !dbg !331
  %call16 = call i64 @wide_shift(i32 noundef 1), !dbg !332
  %conv17 = trunc i64 %call16 to i32, !dbg !333
  %add18 = add nsw i32 %add15, %conv17, !dbg !334
  %call19 = call i32 @skip_empty(i32 noundef 3), !dbg !335
  %add20 = add nsw i32 %add18, %call19, !dbg !336
  %call21 = call i32 @truncated_half(), !dbg !337
  %add22 = add nsw i32 %add20, %call21, !dbg !338
  %call23 = call i32 @last_of_four(), !dbg !339
  %add24 = add nsw i32 %add22, %call23, !dbg !340
  %call25 = call i32 @not_equal(i32 noundef 1, i32 noundef 2), !dbg !341
  %add26 = add nsw i32 %add24, %call25, !dbg !342
  %arraydecay27 = getelementptr inbounds [6 x i32], ptr %values, i64 0, i64 0, !dbg !343
  %call28 = call i32 @array_size(ptr noundef %arraydecay27), !dbg !344
  %add29 = add nsw i32 %add26, %call28, !dbg !345
  %call30 = call i32 @bump(i32 noundef 2), !dbg !346
  %add31 = add nsw i32 %add29, %call30, !dbg !347
  ret i32 %add31, !dbg !348
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
!31 = !DILocation(line: 4, column: 29, scope: !25)
!32 = !DILocalVariable(name: "count", scope: !25, file: !2, line: 5, type: !15)
!33 = !DILocation(line: 5, column: 9, scope: !25)
!34 = !DILocalVariable(name: "bit", scope: !25, file: !2, line: 6, type: !28)
!35 = !DILocation(line: 6, column: 14, scope: !25)
!36 = !DILocation(line: 7, column: 5, scope: !25)
!37 = !DILocation(line: 7, column: 18, scope: !25)
!38 = !DILocation(line: 7, column: 24, scope: !25)
!39 = !DILocation(line: 7, column: 16, scope: !25)
!40 = !DILocation(line: 8, column: 18, scope: !41)
!41 = distinct !DILexicalBlock(scope: !25, file: !2, line: 7, column: 30)
!42 = !DILocation(line: 8, column: 15, scope: !41)
!43 = !DILocation(line: 9, column: 15, scope: !41)
!44 = distinct !{!44, !36, !45, !46}
!45 = !DILocation(line: 10, column: 5, scope: !25)
!46 = !{!"llvm.loop.mustprogress"}
!47 = !DILocation(line: 11, column: 12, scope: !25)
!48 = !DILocation(line: 11, column: 5, scope: !25)
!49 = distinct !DISubprogram(name: "sum_to", scope: !2, file: !2, line: 14, type: !50, scopeLine: 14, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!50 = !DISubroutineType(types: !51)
!51 = !{!15, !15}
!52 = !DILocalVariable(name: "limit", arg: 1, scope: !49, file: !2, line: 14, type: !15)
!53 = !DILocation(line: 14, column: 16, scope: !49)
!54 = !DILocalVariable(name: "total", scope: !49, file: !2, line: 15, type: !15)
!55 = !DILocation(line: 15, column: 9, scope: !49)
!56 = !DILocalVariable(name: "i", scope: !57, file: !2, line: 16, type: !15)
!57 = distinct !DILexicalBlock(scope: !49, file: !2, line: 16, column: 5)
!58 = !DILocation(line: 16, column: 14, scope: !57)
!59 = !DILocation(line: 16, column: 10, scope: !57)
!60 = !DILocation(line: 16, column: 21, scope: !61)
!61 = distinct !DILexicalBlock(scope: !57, file: !2, line: 16, column: 5)
!62 = !DILocation(line: 16, column: 25, scope: !61)
!63 = !DILocation(line: 16, column: 23, scope: !61)
!64 = !DILocation(line: 16, column: 5, scope: !57)
!65 = !DILocation(line: 17, column: 9, scope: !66)
!66 = distinct !DILexicalBlock(scope: !61, file: !2, line: 16, column: 37)
!67 = !DILocation(line: 17, column: 17, scope: !66)
!68 = !DILocation(line: 17, column: 15, scope: !66)
!69 = !DILocation(line: 18, column: 18, scope: !66)
!70 = !DILocation(line: 18, column: 15, scope: !66)
!71 = !DILocation(line: 19, column: 5, scope: !66)
!72 = !DILocation(line: 16, column: 33, scope: !61)
!73 = !DILocation(line: 16, column: 5, scope: !61)
!74 = distinct !{!74, !64, !75, !46}
!75 = !DILocation(line: 19, column: 5, scope: !57)
!76 = !DILocation(line: 20, column: 12, scope: !49)
!77 = !DILocation(line: 20, column: 5, scope: !49)
!78 = distinct !DISubprogram(name: "is_same", scope: !2, file: !2, line: 23, type: !50, scopeLine: 23, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!79 = !DILocalVariable(name: "value", arg: 1, scope: !78, file: !2, line: 23, type: !15)
!80 = !DILocation(line: 23, column: 17, scope: !78)
!81 = !DILocation(line: 24, column: 12, scope: !78)
!82 = !DILocation(line: 24, column: 21, scope: !78)
!83 = !DILocation(line: 24, column: 18, scope: !78)
!84 = !DILocation(line: 24, column: 5, scope: !78)
!85 = distinct !DISubprogram(name: "small_constant", scope: !2, file: !2, line: 27, type: !86, scopeLine: 27, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!86 = !DISubroutineType(types: !87)
!87 = !{!88}
!88 = !DIBasicType(name: "unsigned char", size: 8, encoding: DW_ATE_unsigned_char)
!89 = !DILocalVariable(name: "byte", scope: !85, file: !2, line: 28, type: !88)
!90 = !DILocation(line: 28, column: 19, scope: !85)
!91 = !DILocation(line: 29, column: 12, scope: !85)
!92 = !DILocation(line: 29, column: 5, scope: !85)
!93 = distinct !DISubprogram(name: "wide_shift", scope: !2, file: !2, line: 32, type: !94, scopeLine: 32, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!94 = !DISubroutineType(types: !95)
!95 = !{!96, !15}
!96 = !DIBasicType(name: "long", size: 64, encoding: DW_ATE_signed)
!97 = !DILocalVariable(name: "value", arg: 1, scope: !93, file: !2, line: 32, type: !15)
!98 = !DILocation(line: 32, column: 21, scope: !93)
!99 = !DILocation(line: 33, column: 12, scope: !93)
!100 = !DILocation(line: 33, column: 18, scope: !93)
!101 = !DILocation(line: 33, column: 5, scope: !93)
!102 = distinct !DISubprogram(name: "first_positive", scope: !2, file: !2, line: 36, type: !103, scopeLine: 36, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!103 = !DISubroutineType(types: !104)
!104 = !{!15, !105, !15}
!105 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !106, size: 64)
!106 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !15)
!107 = !DILocalVariable(name: "values", arg: 1, scope: !102, file: !2, line: 36, type: !105)
!108 = !DILocation(line: 36, column: 31, scope: !102)
!109 = !DILocalVariable(name: "count", arg: 2, scope: !102, file: !2, line: 36, type: !15)
!110 = !DILocation(line: 36, column: 43, scope: !102)
!111 = !DILocalVariable(name: "found", scope: !102, file: !2, line: 37, type: !15)
!112 = !DILocation(line: 37, column: 9, scope: !102)
!113 = !DILocalVariable(name: "i", scope: !114, file: !2, line: 38, type: !15)
!114 = distinct !DILexicalBlock(scope: !102, file: !2, line: 38, column: 5)
!115 = !DILocation(line: 38, column: 14, scope: !114)
!116 = !DILocation(line: 38, column: 10, scope: !114)
!117 = !DILocation(line: 38, column: 21, scope: !118)
!118 = distinct !DILexicalBlock(scope: !114, file: !2, line: 38, column: 5)
!119 = !DILocation(line: 38, column: 25, scope: !118)
!120 = !DILocation(line: 38, column: 23, scope: !118)
!121 = !DILocation(line: 38, column: 5, scope: !114)
!122 = !DILocation(line: 39, column: 21, scope: !123)
!123 = distinct !DILexicalBlock(scope: !124, file: !2, line: 39, column: 13)
!124 = distinct !DILexicalBlock(scope: !118, file: !2, line: 38, column: 37)
!125 = !DILocation(line: 39, column: 28, scope: !123)
!126 = !DILocation(line: 39, column: 31, scope: !123)
!127 = !DILocation(line: 39, column: 19, scope: !123)
!128 = !DILocation(line: 40, column: 20, scope: !129)
!129 = distinct !DILexicalBlock(scope: !123, file: !2, line: 39, column: 36)
!130 = !DILocation(line: 40, column: 27, scope: !129)
!131 = !DILocation(line: 40, column: 13, scope: !129)
!132 = !DILocation(line: 42, column: 5, scope: !124)
!133 = !DILocation(line: 38, column: 33, scope: !118)
!134 = !DILocation(line: 38, column: 5, scope: !118)
!135 = distinct !{!135, !121, !136, !46}
!136 = !DILocation(line: 42, column: 5, scope: !114)
!137 = !DILocation(line: 43, column: 5, scope: !102)
!138 = !DILocation(line: 44, column: 1, scope: !102)
!139 = distinct !DISubprogram(name: "skip_empty", scope: !2, file: !2, line: 46, type: !50, scopeLine: 46, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!140 = !DILocalVariable(name: "value", arg: 1, scope: !139, file: !2, line: 46, type: !15)
!141 = !DILocation(line: 46, column: 20, scope: !139)
!142 = !DILocation(line: 47, column: 9, scope: !143)
!143 = distinct !DILexicalBlock(scope: !139, file: !2, line: 47, column: 9)
!144 = !DILocation(line: 47, column: 15, scope: !143)
!145 = !DILocation(line: 48, column: 12, scope: !139)
!146 = !DILocation(line: 48, column: 5, scope: !139)
!147 = distinct !DISubprogram(name: "truncated_half", scope: !2, file: !2, line: 51, type: !148, scopeLine: 51, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!148 = !DISubroutineType(types: !14)
!149 = !DILocalVariable(name: "half", scope: !147, file: !2, line: 52, type: !15)
!150 = !DILocation(line: 52, column: 9, scope: !147)
!151 = !DILocation(line: 53, column: 12, scope: !147)
!152 = !DILocation(line: 53, column: 5, scope: !147)
!153 = distinct !DISubprogram(name: "last_of_four", scope: !2, file: !2, line: 56, type: !148, scopeLine: 56, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!154 = !DILocalVariable(name: "four", scope: !153, file: !2, line: 57, type: !155)
!155 = !DICompositeType(tag: DW_TAG_array_type, baseType: !15, size: 128, elements: !156)
!156 = !{!157}
!157 = !DISubrange(count: 4)
!158 = !DILocation(line: 57, column: 9, scope: !153)
!159 = !DILocation(line: 58, column: 12, scope: !153)
!160 = !DILocation(line: 58, column: 5, scope: !153)
!161 = distinct !DISubprogram(name: "not_equal", scope: !2, file: !2, line: 61, type: !162, scopeLine: 61, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!162 = !DISubroutineType(types: !163)
!163 = !{!15, !15, !15}
!164 = !DILocalVariable(name: "a", arg: 1, scope: !161, file: !2, line: 61, type: !15)
!165 = !DILocation(line: 61, column: 19, scope: !161)
!166 = !DILocalVariable(name: "b", arg: 2, scope: !161, file: !2, line: 61, type: !15)
!167 = !DILocation(line: 61, column: 26, scope: !161)
!168 = !DILocation(line: 62, column: 10, scope: !169)
!169 = distinct !DILexicalBlock(scope: !161, file: !2, line: 62, column: 9)
!170 = !DILocation(line: 62, column: 9, scope: !169)
!171 = !DILocation(line: 62, column: 15, scope: !169)
!172 = !DILocation(line: 62, column: 12, scope: !169)
!173 = !DILocation(line: 63, column: 9, scope: !174)
!174 = distinct !DILexicalBlock(scope: !169, file: !2, line: 62, column: 18)
!175 = !DILocation(line: 65, column: 5, scope: !161)
!176 = !DILocation(line: 66, column: 1, scope: !161)
!177 = distinct !DISubprogram(name: "array_size", scope: !2, file: !2, line: 68, type: !178, scopeLine: 68, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!178 = !DISubroutineType(types: !179)
!179 = !{!15, !180}
!180 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !15, size: 64)
!181 = !DILocalVariable(name: "values", arg: 1, scope: !177, file: !2, line: 68, type: !180)
!182 = !DILocation(line: 68, column: 20, scope: !177)
!183 = !DILocation(line: 69, column: 5, scope: !177)
!184 = distinct !DISubprogram(name: "print_total", scope: !2, file: !2, line: 72, type: !185, scopeLine: 72, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!185 = !DISubroutineType(types: !186)
!186 = !{null, !96, !187}
!187 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!188 = !DILocalVariable(name: "total", arg: 1, scope: !184, file: !2, line: 72, type: !96)
!189 = !DILocation(line: 72, column: 23, scope: !184)
!190 = !DILocalVariable(name: "mean", arg: 2, scope: !184, file: !2, line: 72, type: !187)
!191 = !DILocation(line: 72, column: 37, scope: !184)
!192 = !DILocation(line: 73, column: 26, scope: !184)
!193 = !DILocation(line: 73, column: 5, scope: !184)
!194 = !DILocation(line: 74, column: 25, scope: !184)
!195 = !DILocation(line: 74, column: 5, scope: !184)
!196 = !DILocation(line: 75, column: 1, scope: !184)
!197 = distinct !DISubprogram(name: "scaled_sum", scope: !2, file: !2, line: 77, type: !103, scopeLine: 77, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!198 = !DILocalVariable(name: "values", arg: 1, scope: !197, file: !2, line: 77, type: !105)
!199 = !DILocation(line: 77, column: 27, scope: !197)
!200 = !DILocalVariable(name: "count", arg: 2, scope: !197, file: !2, line: 77, type: !15)
!201 = !DILocation(line: 77, column: 39, scope: !197)
!202 = !DILocalVariable(name: "total", scope: !197, file: !2, line: 78, type: !15)
!203 = !DILocation(line: 78, column: 9, scope: !197)
!204 = !DILocalVariable(name: "i", scope: !205, file: !2, line: 79, type: !15)
!205 = distinct !DILexicalBlock(scope: !197, file: !2, line: 79, column: 5)
!206 = !DILocation(line: 79, column: 14, scope: !205)
!207 = !DILocation(line: 79, column: 10, scope: !205)
!208 = !DILocation(line: 79, column: 21, scope: !209)
!209 = distinct !DILexicalBlock(scope: !205, file: !2, line: 79, column: 5)
!210 = !DILocation(line: 79, column: 25, scope: !209)
!211 = !DILocation(line: 79, column: 23, scope: !209)
!212 = !DILocation(line: 79, column: 5, scope: !205)
!213 = !DILocation(line: 80, column: 21, scope: !214)
!214 = distinct !DILexicalBlock(scope: !215, file: !2, line: 80, column: 13)
!215 = distinct !DILexicalBlock(scope: !209, file: !2, line: 79, column: 37)
!216 = !DILocation(line: 80, column: 29, scope: !214)
!217 = !DILocation(line: 80, column: 36, scope: !214)
!218 = !DILocation(line: 80, column: 39, scope: !214)
!219 = !DILocation(line: 80, column: 27, scope: !214)
!220 = !DILocation(line: 80, column: 19, scope: !214)
!221 = !DILocation(line: 81, column: 13, scope: !222)
!222 = distinct !DILexicalBlock(scope: !214, file: !2, line: 80, column: 44)
!223 = !DILocation(line: 81, column: 19, scope: !222)
!224 = !DILocation(line: 82, column: 9, scope: !222)
!225 = !DILocation(line: 83, column: 5, scope: !215)
!226 = !DILocation(line: 79, column: 33, scope: !209)
!227 = !DILocation(line: 79, column: 5, scope: !209)
!228 = distinct !{!228, !212, !229, !46}
!229 = !DILocation(line: 83, column: 5, scope: !205)
!230 = !DILocation(line: 84, column: 12, scope: !197)
!231 = !DILocation(line: 84, column: 5, scope: !197)
!232 = distinct !DISubprogram(name: "clamp", scope: !2, file: !2, line: 87, type: !50, scopeLine: 87, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!233 = !DILocalVariable(name: "value", arg: 1, scope: !232, file: !2, line: 87, type: !15)
!234 = !DILocation(line: 87, column: 15, scope: !232)
!235 = !DILocalVariable(name: "low", scope: !232, file: !2, line: 88, type: !4)
!236 = !DILocation(line: 88, column: 10, scope: !232)
!237 = !DILocalVariable(name: "high", scope: !232, file: !2, line: 89, type: !4)
!238 = !DILocation(line: 89, column: 10, scope: !232)
!239 = !DILocation(line: 90, column: 9, scope: !240)
!240 = distinct !DILexicalBlock(scope: !232, file: !2, line: 90, column: 9)
!241 = !DILocation(line: 90, column: 17, scope: !240)
!242 = !DILocation(line: 90, column: 15, scope: !240)
!243 = !DILocation(line: 91, column: 16, scope: !244)
!244 = distinct !DILexicalBlock(scope: !240, file: !2, line: 90, column: 22)
!245 = !DILocation(line: 91, column: 9, scope: !244)
!246 = !DILocation(line: 93, column: 9, scope: !247)
!247 = distinct !DILexicalBlock(scope: !232, file: !2, line: 93, column: 9)
!248 = !DILocation(line: 93, column: 17, scope: !247)
!249 = !DILocation(line: 93, column: 15, scope: !247)
!250 = !DILocation(line: 94, column: 16, scope: !251)
!251 = distinct !DILexicalBlock(scope: !247, file: !2, line: 93, column: 23)
!252 = !DILocation(line: 94, column: 9, scope: !251)
!253 = !DILocation(line: 96, column: 12, scope: !232)
!254 = !DILocation(line: 96, column: 5, scope: !232)
!255 = !DILocation(line: 97, column: 1, scope: !232)
!256 = distinct !DISubprogram(name: "max_of", scope: !2, file: !2, line: 99, type: !103, scopeLine: 99, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!257 = !DILocalVariable(name: "values", arg: 1, scope: !256, file: !2, line: 99, type: !105)
!258 = !DILocation(line: 99, column: 23, scope: !256)
!259 = !DILocalVariable(name: "count", arg: 2, scope: !256, file: !2, line: 99, type: !15)
!260 = !DILocation(line: 99, column: 35, scope: !256)
!261 = !DILocalVariable(name: "best", scope: !256, file: !2, line: 100, type: !15)
!262 = !DILocation(line: 100, column: 9, scope: !256)
!263 = !DILocation(line: 100, column: 16, scope: !256)
!264 = !DILocalVariable(name: "i", scope: !265, file: !2, line: 101, type: !15)
!265 = distinct !DILexicalBlock(scope: !256, file: !2, line: 101, column: 5)
!266 = !DILocation(line: 101, column: 14, scope: !265)
!267 = !DILocation(line: 101, column: 10, scope: !265)
!268 = !DILocation(line: 101, column: 21, scope: !269)
!269 = distinct !DILexicalBlock(scope: !265, file: !2, line: 101, column: 5)
!270 = !DILocation(line: 101, column: 25, scope: !269)
!271 = !DILocation(line: 101, column: 23, scope: !269)
!272 = !DILocation(line: 101, column: 5, scope: !265)
!273 = !DILocation(line: 102, column: 20, scope: !274)
!274 = distinct !DILexicalBlock(scope: !275, file: !2, line: 102, column: 13)
!275 = distinct !DILexicalBlock(scope: !269, file: !2, line: 101, column: 37)
!276 = !DILocation(line: 102, column: 27, scope: !274)
!277 = !DILocation(line: 102, column: 32, scope: !274)
!278 = !DILocation(line: 102, column: 30, scope: !274)
!279 = !DILocation(line: 102, column: 39, scope: !274)
!280 = !DILocation(line: 102, column: 46, scope: !274)
!281 = !DILocation(line: 102, column: 51, scope: !274)
!282 = !DILocation(line: 102, column: 18, scope: !274)
!283 = !DILocation(line: 103, column: 13, scope: !284)
!284 = distinct !DILexicalBlock(scope: !274, file: !2, line: 102, column: 57)
!285 = !DILocation(line: 103, column: 21, scope: !284)
!286 = !DILocation(line: 103, column: 28, scope: !284)
!287 = !DILocation(line: 103, column: 18, scope: !284)
!288 = !DILocation(line: 104, column: 9, scope: !284)
!289 = !DILocation(line: 105, column: 5, scope: !275)
!290 = !DILocation(line: 101, column: 33, scope: !269)
!291 = !DILocation(line: 101, column: 5, scope: !269)
!292 = distinct !{!292, !272, !293, !46}
!293 = !DILocation(line: 105, column: 5, scope: !265)
!294 = !DILocation(line: 106, column: 12, scope: !256)
!295 = !DILocation(line: 106, column: 5, scope: !256)
!296 = distinct !DISubprogram(name: "bump", scope: !2, file: !2, line: 109, type: !50, scopeLine: 109, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!297 = !DILocalVariable(name: "i", arg: 1, scope: !296, file: !2, line: 109, type: !15)
!298 = !DILocation(line: 109, column: 14, scope: !296)
!299 = !DILocation(line: 110, column: 10, scope: !296)
!300 = !DILocation(line: 110, column: 13, scope: !296)
!301 = !DILocation(line: 110, column: 7, scope: !296)
!302 = !DILocation(line: 111, column: 12, scope: !296)
!303 = !DILocation(line: 111, column: 16, scope: !296)
!304 = !DILocation(line: 111, column: 14, scope: !296)
!305 = !DILocation(line: 111, column: 24, scope: !296)
!306 = !DILocation(line: 111, column: 5, scope: !296)
!307 = distinct !DISubprogram(name: "main", scope: !2, file: !2, line: 114, type: !148, scopeLine: 114, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!308 = !DILocalVariable(name: "values", scope: !307, file: !2, line: 115, type: !309)
!309 = !DICompositeType(tag: DW_TAG_array_type, baseType: !15, size: 192, elements: !310)
!310 = !{!311}
!311 = !DISubrange(count: 6)
!312 = !DILocation(line: 115, column: 9, scope: !307)
!313 = !DILocation(line: 116, column: 17, scope: !307)
!314 = !DILocation(line: 116, column: 5, scope: !307)
!315 = !DILocation(line: 117, column: 27, scope: !307)
!316 = !DILocation(line: 117, column: 12, scope: !307)
!317 = !DILocation(line: 117, column: 47, scope: !307)
!318 = !DILocation(line: 117, column: 40, scope: !307)
!319 = !DILocation(line: 117, column: 38, scope: !307)
!320 = !DILocation(line: 117, column: 71, scope: !307)
!321 = !DILocation(line: 117, column: 60, scope: !307)
!322 = !DILocation(line: 117, column: 58, scope: !307)
!323 = !DILocation(line: 117, column: 90, scope: !307)
!324 = !DILocation(line: 117, column: 84, scope: !307)
!325 = !DILocation(line: 117, column: 82, scope: !307)
!326 = !DILocation(line: 118, column: 11, scope: !307)
!327 = !DILocation(line: 118, column: 9, scope: !307)
!328 = !DILocation(line: 118, column: 34, scope: !307)
!329 = !DILocation(line: 118, column: 32, scope: !307)
!330 = !DILocation(line: 118, column: 47, scope: !307)
!331 = !DILocation(line: 118, column: 45, scope: !307)
!332 = !DILocation(line: 118, column: 71, scope: !307)
!333 = !DILocation(line: 118, column: 66, scope: !307)
!334 = !DILocation(line: 118, column: 64, scope: !307)
!335 = !DILocation(line: 118, column: 87, scope: !307)
!336 = !DILocation(line: 118, column: 85, scope: !307)
!337 = !DILocation(line: 119, column: 11, scope: !307)
!338 = !DILocation(line: 119, column: 9, scope: !307)
!339 = !DILocation(line: 119, column: 30, scope: !307)
!340 = !DILocation(line: 119, column: 28, scope: !307)
!341 = !DILocation(line: 119, column: 47, scope: !307)
!342 = !DILocation(line: 119, column: 45, scope: !307)
!343 = !DILocation(line: 119, column: 76, scope: !307)
!344 = !DILocation(line: 119, column: 65, scope: !307)
!345 = !DILocation(line: 119, column: 63, scope: !307)
!346 = !DILocation(line: 119, column: 86, scope: !307)
!347 = !DILocation(line: 119, column: 84, scope: !307)
!348 = !DILocation(line: 117, column: 5, scope: !307)
