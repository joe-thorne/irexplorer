; ModuleID = '/workspace/user-programs/word_frequency.c'
source_filename = "/workspace/user-programs/word_frequency.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%struct.table = type { [256 x %struct.entry], i32 }
%struct.entry = type { [24 x i8], i32, i32 }

@main.table = internal global %struct.table zeroinitializer, align 4, !dbg !0
@main.entries = internal global [256 x %struct.entry] zeroinitializer, align 16, !dbg !37
@passage = internal global ptr @.str.4, align 8, !dbg !72
@.str = private unnamed_addr constant [4 x i8] c"fox\00", align 1, !dbg !50
@.str.1 = private unnamed_addr constant [4 x i8] c"cat\00", align 1, !dbg !55
@.str.2 = private unnamed_addr constant [18 x i8] c"fox: %d, cat: %d\0A\00", align 1, !dbg !57
@stderr = external global ptr, align 8
@.str.3 = private unnamed_addr constant [23 x i8] c"table full at word %d\0A\00", align 1, !dbg !62
@.str.4 = private unnamed_addr constant [285 x i8] c"The quick brown fox jumps over the lazy dog. The dog sleeps, and the fox runs into the forest. In the forest the fox finds a river; the river is cold and the fox is quick. A lazy dog never finds the river, but the quick fox always does. Over the hills and over the river the fox runs.\00", align 1, !dbg !67
@.str.5 = private unnamed_addr constant [23 x i8] c"%d words, %d distinct\0A\00", align 1, !dbg !76
@.str.6 = private unnamed_addr constant [11 x i8] c"%-10s %3d \00", align 1, !dbg !78
@.str.7 = private unnamed_addr constant [18 x i8] c"longest word: %s\0A\00", align 1, !dbg !83
@.str.8 = private unnamed_addr constant [27 x i8] c"mean length: %.2f letters\0A\00", align 1, !dbg !85
@.str.9 = private unnamed_addr constant [21 x i8] c"words seen once: %d\0A\00", align 1, !dbg !90

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @main() #0 !dbg !2 {
entry:
  %retval = alloca i32, align 4
  %total = alloca i32, align 4
  %n = alloca i32, align 4
  %foxes = alloca i32, align 4
  %cats = alloca i32, align 4
  store i32 0, ptr %retval, align 4
  call void @table_init(ptr noundef @main.table), !dbg !108
    #dbg_declare(ptr %total, !109, !DIExpression(), !110)
  %0 = load ptr, ptr @passage, align 8, !dbg !111
  %call = call i32 @count_words(ptr noundef @main.table, ptr noundef %0), !dbg !112
  store i32 %call, ptr %total, align 4, !dbg !110
    #dbg_declare(ptr %n, !113, !DIExpression(), !114)
  %call1 = call i32 @collect(ptr noundef @main.table, ptr noundef @main.entries), !dbg !115
  store i32 %call1, ptr %n, align 4, !dbg !114
  %1 = load i32, ptr %n, align 4, !dbg !116
  %2 = load i32, ptr %total, align 4, !dbg !117
  call void @report(ptr noundef @main.entries, i32 noundef %1, i32 noundef %2), !dbg !118
    #dbg_declare(ptr %foxes, !119, !DIExpression(), !120)
  %call2 = call i32 @table_lookup(ptr noundef @main.table, ptr noundef @.str), !dbg !121
  store i32 %call2, ptr %foxes, align 4, !dbg !120
    #dbg_declare(ptr %cats, !122, !DIExpression(), !123)
  %call3 = call i32 @table_lookup(ptr noundef @main.table, ptr noundef @.str.1), !dbg !124
  store i32 %call3, ptr %cats, align 4, !dbg !123
  %3 = load i32, ptr %foxes, align 4, !dbg !125
  %4 = load i32, ptr %cats, align 4, !dbg !126
  %call4 = call i32 (ptr, ...) @printf(ptr noundef @.str.2, i32 noundef %3, i32 noundef %4), !dbg !127
  %5 = load i32, ptr %foxes, align 4, !dbg !128
  %cmp = icmp sgt i32 %5, 0, !dbg !129
  br i1 %cmp, label %land.rhs, label %land.end, !dbg !130

land.rhs:                                         ; preds = %entry
  %6 = load i32, ptr %cats, align 4, !dbg !131
  %cmp5 = icmp eq i32 %6, 0, !dbg !132
  br label %land.end

land.end:                                         ; preds = %land.rhs, %entry
  %7 = phi i1 [ false, %entry ], [ %cmp5, %land.rhs ], !dbg !133
  %8 = zext i1 %7 to i64, !dbg !128
  %cond = select i1 %7, i32 0, i32 1, !dbg !128
  ret i32 %cond, !dbg !134
}

; Function Attrs: noinline nounwind uwtable
define internal void @table_init(ptr noundef %table) #0 !dbg !135 {
entry:
  %table.addr = alloca ptr, align 8
  store ptr %table, ptr %table.addr, align 8
    #dbg_declare(ptr %table.addr, !139, !DIExpression(), !140)
  %0 = load ptr, ptr %table.addr, align 8, !dbg !141
  call void @llvm.memset.p0.i64(ptr align 4 %0, i8 0, i64 8196, i1 false), !dbg !142
  ret void, !dbg !143
}

; Function Attrs: noinline nounwind uwtable
define internal i32 @count_words(ptr noundef %table, ptr noundef %text) #0 !dbg !144 {
entry:
  %table.addr = alloca ptr, align 8
  %text.addr = alloca ptr, align 8
  %word = alloca [24 x i8], align 16
  %position = alloca i32, align 4
  store ptr %table, ptr %table.addr, align 8
    #dbg_declare(ptr %table.addr, !147, !DIExpression(), !148)
  store ptr %text, ptr %text.addr, align 8
    #dbg_declare(ptr %text.addr, !149, !DIExpression(), !150)
    #dbg_declare(ptr %word, !151, !DIExpression(), !152)
    #dbg_declare(ptr %position, !153, !DIExpression(), !154)
  store i32 0, ptr %position, align 4, !dbg !154
  br label %while.cond, !dbg !155

while.cond:                                       ; preds = %if.end, %entry
  %arraydecay = getelementptr inbounds [24 x i8], ptr %word, i64 0, i64 0, !dbg !156
  %call = call i32 @next_word(ptr noundef %text.addr, ptr noundef %arraydecay), !dbg !157
  %cmp = icmp sgt i32 %call, 0, !dbg !158
  br i1 %cmp, label %while.body, label %while.end, !dbg !155

while.body:                                       ; preds = %while.cond
  %0 = load ptr, ptr %table.addr, align 8, !dbg !159
  %arraydecay1 = getelementptr inbounds [24 x i8], ptr %word, i64 0, i64 0, !dbg !162
  %1 = load i32, ptr %position, align 4, !dbg !163
  %call2 = call i32 @table_add(ptr noundef %0, ptr noundef %arraydecay1, i32 noundef %1), !dbg !164
  %cmp3 = icmp slt i32 %call2, 0, !dbg !165
  br i1 %cmp3, label %if.then, label %if.end, !dbg !165

if.then:                                          ; preds = %while.body
  %2 = load ptr, ptr @stderr, align 8, !dbg !166
  %3 = load i32, ptr %position, align 4, !dbg !168
  %call4 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %2, ptr noundef @.str.3, i32 noundef %3) #7, !dbg !169
  br label %while.end, !dbg !170

if.end:                                           ; preds = %while.body
  %4 = load i32, ptr %position, align 4, !dbg !171
  %inc = add nsw i32 %4, 1, !dbg !171
  store i32 %inc, ptr %position, align 4, !dbg !171
  br label %while.cond, !dbg !155, !llvm.loop !172

while.end:                                        ; preds = %if.then, %while.cond
  %5 = load i32, ptr %position, align 4, !dbg !175
  ret i32 %5, !dbg !176
}

; Function Attrs: noinline nounwind uwtable
define internal i32 @collect(ptr noundef %table, ptr noundef %out) #0 !dbg !177 {
entry:
  %table.addr = alloca ptr, align 8
  %out.addr = alloca ptr, align 8
  %n = alloca i32, align 4
  %i = alloca i32, align 4
  store ptr %table, ptr %table.addr, align 8
    #dbg_declare(ptr %table.addr, !183, !DIExpression(), !184)
  store ptr %out, ptr %out.addr, align 8
    #dbg_declare(ptr %out.addr, !185, !DIExpression(), !186)
    #dbg_declare(ptr %n, !187, !DIExpression(), !188)
  store i32 0, ptr %n, align 4, !dbg !188
    #dbg_declare(ptr %i, !189, !DIExpression(), !191)
  store i32 0, ptr %i, align 4, !dbg !191
  br label %for.cond, !dbg !192

for.cond:                                         ; preds = %for.inc, %entry
  %0 = load i32, ptr %i, align 4, !dbg !193
  %cmp = icmp slt i32 %0, 256, !dbg !195
  br i1 %cmp, label %for.body, label %for.end, !dbg !196

for.body:                                         ; preds = %for.cond
  %1 = load ptr, ptr %table.addr, align 8, !dbg !197
  %slots = getelementptr inbounds nuw %struct.table, ptr %1, i32 0, i32 0, !dbg !200
  %2 = load i32, ptr %i, align 4, !dbg !201
  %idxprom = sext i32 %2 to i64, !dbg !197
  %arrayidx = getelementptr inbounds [256 x %struct.entry], ptr %slots, i64 0, i64 %idxprom, !dbg !197
  %count = getelementptr inbounds nuw %struct.entry, ptr %arrayidx, i32 0, i32 1, !dbg !202
  %3 = load i32, ptr %count, align 4, !dbg !202
  %cmp1 = icmp sgt i32 %3, 0, !dbg !203
  br i1 %cmp1, label %if.then, label %if.end, !dbg !203

if.then:                                          ; preds = %for.body
  %4 = load ptr, ptr %out.addr, align 8, !dbg !204
  %5 = load i32, ptr %n, align 4, !dbg !206
  %inc = add nsw i32 %5, 1, !dbg !206
  store i32 %inc, ptr %n, align 4, !dbg !206
  %idxprom2 = sext i32 %5 to i64, !dbg !204
  %arrayidx3 = getelementptr inbounds %struct.entry, ptr %4, i64 %idxprom2, !dbg !204
  %6 = load ptr, ptr %table.addr, align 8, !dbg !207
  %slots4 = getelementptr inbounds nuw %struct.table, ptr %6, i32 0, i32 0, !dbg !208
  %7 = load i32, ptr %i, align 4, !dbg !209
  %idxprom5 = sext i32 %7 to i64, !dbg !207
  %arrayidx6 = getelementptr inbounds [256 x %struct.entry], ptr %slots4, i64 0, i64 %idxprom5, !dbg !207
  call void @llvm.memcpy.p0.p0.i64(ptr align 4 %arrayidx3, ptr align 4 %arrayidx6, i64 32, i1 false), !dbg !207
  br label %if.end, !dbg !210

if.end:                                           ; preds = %if.then, %for.body
  br label %for.inc, !dbg !211

for.inc:                                          ; preds = %if.end
  %8 = load i32, ptr %i, align 4, !dbg !212
  %inc7 = add nsw i32 %8, 1, !dbg !212
  store i32 %inc7, ptr %i, align 4, !dbg !212
  br label %for.cond, !dbg !213, !llvm.loop !214

for.end:                                          ; preds = %for.cond
  %9 = load ptr, ptr %out.addr, align 8, !dbg !216
  %10 = load i32, ptr %n, align 4, !dbg !217
  %conv = sext i32 %10 to i64, !dbg !218
  call void @qsort(ptr noundef %9, i64 noundef %conv, i64 noundef 32, ptr noundef @by_count), !dbg !219
  %11 = load i32, ptr %n, align 4, !dbg !220
  ret i32 %11, !dbg !221
}

; Function Attrs: noinline nounwind uwtable
define internal void @report(ptr noundef %entries, i32 noundef %n, i32 noundef %total) #0 !dbg !222 {
entry:
  %entries.addr = alloca ptr, align 8
  %n.addr = alloca i32, align 4
  %total.addr = alloca i32, align 4
  %shown = alloca i32, align 4
  %i = alloca i32, align 4
  %word10 = alloca ptr, align 8
  store ptr %entries, ptr %entries.addr, align 8
    #dbg_declare(ptr %entries.addr, !227, !DIExpression(), !228)
  store i32 %n, ptr %n.addr, align 4
    #dbg_declare(ptr %n.addr, !229, !DIExpression(), !230)
  store i32 %total, ptr %total.addr, align 4
    #dbg_declare(ptr %total.addr, !231, !DIExpression(), !232)
    #dbg_declare(ptr %shown, !233, !DIExpression(), !234)
  %0 = load i32, ptr %n.addr, align 4, !dbg !235
  %cmp = icmp slt i32 %0, 8, !dbg !236
  br i1 %cmp, label %cond.true, label %cond.false, !dbg !235

cond.true:                                        ; preds = %entry
  %1 = load i32, ptr %n.addr, align 4, !dbg !237
  br label %cond.end, !dbg !235

cond.false:                                       ; preds = %entry
  br label %cond.end, !dbg !235

cond.end:                                         ; preds = %cond.false, %cond.true
  %cond = phi i32 [ %1, %cond.true ], [ 8, %cond.false ], !dbg !235
  store i32 %cond, ptr %shown, align 4, !dbg !234
  %2 = load i32, ptr %total.addr, align 4, !dbg !238
  %3 = load i32, ptr %n.addr, align 4, !dbg !239
  %call = call i32 (ptr, ...) @printf(ptr noundef @.str.5, i32 noundef %2, i32 noundef %3), !dbg !240
    #dbg_declare(ptr %i, !241, !DIExpression(), !243)
  store i32 0, ptr %i, align 4, !dbg !243
  br label %for.cond, !dbg !244

for.cond:                                         ; preds = %for.inc, %cond.end
  %4 = load i32, ptr %i, align 4, !dbg !245
  %5 = load i32, ptr %shown, align 4, !dbg !247
  %cmp1 = icmp slt i32 %4, %5, !dbg !248
  br i1 %cmp1, label %for.body, label %for.end, !dbg !249

for.body:                                         ; preds = %for.cond
  %6 = load ptr, ptr %entries.addr, align 8, !dbg !250
  %7 = load i32, ptr %i, align 4, !dbg !252
  %idxprom = sext i32 %7 to i64, !dbg !250
  %arrayidx = getelementptr inbounds %struct.entry, ptr %6, i64 %idxprom, !dbg !250
  %word = getelementptr inbounds nuw %struct.entry, ptr %arrayidx, i32 0, i32 0, !dbg !253
  %arraydecay = getelementptr inbounds [24 x i8], ptr %word, i64 0, i64 0, !dbg !250
  %8 = load ptr, ptr %entries.addr, align 8, !dbg !254
  %9 = load i32, ptr %i, align 4, !dbg !255
  %idxprom2 = sext i32 %9 to i64, !dbg !254
  %arrayidx3 = getelementptr inbounds %struct.entry, ptr %8, i64 %idxprom2, !dbg !254
  %count = getelementptr inbounds nuw %struct.entry, ptr %arrayidx3, i32 0, i32 1, !dbg !256
  %10 = load i32, ptr %count, align 4, !dbg !256
  %call4 = call i32 (ptr, ...) @printf(ptr noundef @.str.6, ptr noundef %arraydecay, i32 noundef %10), !dbg !257
  %11 = load ptr, ptr %entries.addr, align 8, !dbg !258
  %12 = load i32, ptr %i, align 4, !dbg !259
  %idxprom5 = sext i32 %12 to i64, !dbg !258
  %arrayidx6 = getelementptr inbounds %struct.entry, ptr %11, i64 %idxprom5, !dbg !258
  %count7 = getelementptr inbounds nuw %struct.entry, ptr %arrayidx6, i32 0, i32 1, !dbg !260
  %13 = load i32, ptr %count7, align 4, !dbg !260
  %14 = load ptr, ptr %entries.addr, align 8, !dbg !261
  %arrayidx8 = getelementptr inbounds %struct.entry, ptr %14, i64 0, !dbg !261
  %count9 = getelementptr inbounds nuw %struct.entry, ptr %arrayidx8, i32 0, i32 1, !dbg !262
  %15 = load i32, ptr %count9, align 4, !dbg !262
  call void @print_bar(i32 noundef %13, i32 noundef %15), !dbg !263
  br label %for.inc, !dbg !264

for.inc:                                          ; preds = %for.body
  %16 = load i32, ptr %i, align 4, !dbg !265
  %inc = add nsw i32 %16, 1, !dbg !265
  store i32 %inc, ptr %i, align 4, !dbg !265
  br label %for.cond, !dbg !266, !llvm.loop !267

for.end:                                          ; preds = %for.cond
    #dbg_declare(ptr %word10, !269, !DIExpression(), !270)
  %17 = load ptr, ptr %entries.addr, align 8, !dbg !271
  %18 = load i32, ptr %n.addr, align 4, !dbg !272
  %call11 = call ptr @longest(ptr noundef %17, i32 noundef %18), !dbg !273
  store ptr %call11, ptr %word10, align 8, !dbg !270
  %19 = load ptr, ptr %word10, align 8, !dbg !274
  %cmp12 = icmp ne ptr %19, null, !dbg !276
  br i1 %cmp12, label %if.then, label %if.end, !dbg !276

if.then:                                          ; preds = %for.end
  %20 = load ptr, ptr %word10, align 8, !dbg !277
  %word13 = getelementptr inbounds nuw %struct.entry, ptr %20, i32 0, i32 0, !dbg !279
  %arraydecay14 = getelementptr inbounds [24 x i8], ptr %word13, i64 0, i64 0, !dbg !277
  %call15 = call i32 (ptr, ...) @printf(ptr noundef @.str.7, ptr noundef %arraydecay14), !dbg !280
  br label %if.end, !dbg !281

if.end:                                           ; preds = %if.then, %for.end
  %21 = load ptr, ptr %entries.addr, align 8, !dbg !282
  %22 = load i32, ptr %n.addr, align 4, !dbg !283
  %call16 = call double @mean_length(ptr noundef %21, i32 noundef %22), !dbg !284
  %call17 = call i32 (ptr, ...) @printf(ptr noundef @.str.8, double noundef %call16), !dbg !285
  %23 = load ptr, ptr %entries.addr, align 8, !dbg !286
  %24 = load i32, ptr %n.addr, align 4, !dbg !287
  %call18 = call i32 @singletons(ptr noundef %23, i32 noundef %24), !dbg !288
  %call19 = call i32 (ptr, ...) @printf(ptr noundef @.str.9, i32 noundef %call18), !dbg !289
  ret void, !dbg !290
}

; Function Attrs: noinline nounwind uwtable
define internal i32 @table_lookup(ptr noundef %table, ptr noundef %word) #0 !dbg !291 {
entry:
  %retval = alloca i32, align 4
  %table.addr = alloca ptr, align 8
  %word.addr = alloca ptr, align 8
  %index = alloca i32, align 4
  %probe = alloca i32, align 4
  %slot = alloca ptr, align 8
  store ptr %table, ptr %table.addr, align 8
    #dbg_declare(ptr %table.addr, !294, !DIExpression(), !295)
  store ptr %word, ptr %word.addr, align 8
    #dbg_declare(ptr %word.addr, !296, !DIExpression(), !297)
    #dbg_declare(ptr %index, !298, !DIExpression(), !299)
  %0 = load ptr, ptr %word.addr, align 8, !dbg !300
  %call = call i32 @hash_word(ptr noundef %0), !dbg !301
  %rem = urem i32 %call, 256, !dbg !302
  store i32 %rem, ptr %index, align 4, !dbg !299
    #dbg_declare(ptr %probe, !303, !DIExpression(), !305)
  store i32 0, ptr %probe, align 4, !dbg !305
  br label %for.cond, !dbg !306

for.cond:                                         ; preds = %for.inc, %entry
  %1 = load i32, ptr %probe, align 4, !dbg !307
  %cmp = icmp slt i32 %1, 256, !dbg !309
  br i1 %cmp, label %for.body, label %for.end, !dbg !310

for.body:                                         ; preds = %for.cond
    #dbg_declare(ptr %slot, !311, !DIExpression(), !313)
  %2 = load ptr, ptr %table.addr, align 8, !dbg !314
  %slots = getelementptr inbounds nuw %struct.table, ptr %2, i32 0, i32 0, !dbg !315
  %3 = load i32, ptr %index, align 4, !dbg !316
  %idxprom = zext i32 %3 to i64, !dbg !314
  %arrayidx = getelementptr inbounds nuw [256 x %struct.entry], ptr %slots, i64 0, i64 %idxprom, !dbg !314
  store ptr %arrayidx, ptr %slot, align 8, !dbg !313
  %4 = load ptr, ptr %slot, align 8, !dbg !317
  %count = getelementptr inbounds nuw %struct.entry, ptr %4, i32 0, i32 1, !dbg !319
  %5 = load i32, ptr %count, align 4, !dbg !319
  %cmp1 = icmp eq i32 %5, 0, !dbg !320
  br i1 %cmp1, label %if.then, label %if.end, !dbg !320

if.then:                                          ; preds = %for.body
  store i32 0, ptr %retval, align 4, !dbg !321
  br label %return, !dbg !321

if.end:                                           ; preds = %for.body
  %6 = load ptr, ptr %slot, align 8, !dbg !323
  %word2 = getelementptr inbounds nuw %struct.entry, ptr %6, i32 0, i32 0, !dbg !325
  %arraydecay = getelementptr inbounds [24 x i8], ptr %word2, i64 0, i64 0, !dbg !323
  %7 = load ptr, ptr %word.addr, align 8, !dbg !326
  %call3 = call i32 @strcmp(ptr noundef %arraydecay, ptr noundef %7) #8, !dbg !327
  %cmp4 = icmp eq i32 %call3, 0, !dbg !328
  br i1 %cmp4, label %if.then5, label %if.end7, !dbg !328

if.then5:                                         ; preds = %if.end
  %8 = load ptr, ptr %slot, align 8, !dbg !329
  %count6 = getelementptr inbounds nuw %struct.entry, ptr %8, i32 0, i32 1, !dbg !331
  %9 = load i32, ptr %count6, align 4, !dbg !331
  store i32 %9, ptr %retval, align 4, !dbg !332
  br label %return, !dbg !332

if.end7:                                          ; preds = %if.end
  %10 = load i32, ptr %index, align 4, !dbg !333
  %add = add i32 %10, 1, !dbg !334
  %rem8 = urem i32 %add, 256, !dbg !335
  store i32 %rem8, ptr %index, align 4, !dbg !336
  br label %for.inc, !dbg !337

for.inc:                                          ; preds = %if.end7
  %11 = load i32, ptr %probe, align 4, !dbg !338
  %inc = add nsw i32 %11, 1, !dbg !338
  store i32 %inc, ptr %probe, align 4, !dbg !338
  br label %for.cond, !dbg !339, !llvm.loop !340

for.end:                                          ; preds = %for.cond
  store i32 0, ptr %retval, align 4, !dbg !342
  br label %return, !dbg !342

return:                                           ; preds = %for.end, %if.then5, %if.then
  %12 = load i32, ptr %retval, align 4, !dbg !343
  ret i32 %12, !dbg !343
}

declare i32 @printf(ptr noundef, ...) #1

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr writeonly captures(none), i8, i64, i1 immarg) #2

; Function Attrs: noinline nounwind uwtable
define internal i32 @next_word(ptr noundef %text, ptr noundef %word) #0 !dbg !344 {
entry:
  %text.addr = alloca ptr, align 8
  %word.addr = alloca ptr, align 8
  %p = alloca ptr, align 8
  %length = alloca i32, align 4
  store ptr %text, ptr %text.addr, align 8
    #dbg_declare(ptr %text.addr, !349, !DIExpression(), !350)
  store ptr %word, ptr %word.addr, align 8
    #dbg_declare(ptr %word.addr, !351, !DIExpression(), !352)
    #dbg_declare(ptr %p, !353, !DIExpression(), !354)
  %0 = load ptr, ptr %text.addr, align 8, !dbg !355
  %1 = load ptr, ptr %0, align 8, !dbg !356
  store ptr %1, ptr %p, align 8, !dbg !354
  br label %while.cond, !dbg !357

while.cond:                                       ; preds = %while.body, %entry
  %2 = load ptr, ptr %p, align 8, !dbg !358
  %3 = load i8, ptr %2, align 1, !dbg !359
  %conv = sext i8 %3 to i32, !dbg !359
  %cmp = icmp ne i32 %conv, 0, !dbg !360
  br i1 %cmp, label %land.rhs, label %land.end, !dbg !361

land.rhs:                                         ; preds = %while.cond
  %call = call ptr @__ctype_b_loc() #9, !dbg !362
  %4 = load ptr, ptr %call, align 8, !dbg !362
  %5 = load ptr, ptr %p, align 8, !dbg !363
  %6 = load i8, ptr %5, align 1, !dbg !364
  %conv2 = zext i8 %6 to i32, !dbg !362
  %idxprom = sext i32 %conv2 to i64, !dbg !362
  %arrayidx = getelementptr inbounds i16, ptr %4, i64 %idxprom, !dbg !362
  %7 = load i16, ptr %arrayidx, align 2, !dbg !362
  %conv3 = zext i16 %7 to i32, !dbg !362
  %and = and i32 %conv3, 1024, !dbg !362
  %tobool = icmp ne i32 %and, 0, !dbg !365
  %lnot = xor i1 %tobool, true, !dbg !365
  br label %land.end

land.end:                                         ; preds = %land.rhs, %while.cond
  %8 = phi i1 [ false, %while.cond ], [ %lnot, %land.rhs ], !dbg !366
  br i1 %8, label %while.body, label %while.end, !dbg !357

while.body:                                       ; preds = %land.end
  %9 = load ptr, ptr %p, align 8, !dbg !367
  %incdec.ptr = getelementptr inbounds nuw i8, ptr %9, i32 1, !dbg !367
  store ptr %incdec.ptr, ptr %p, align 8, !dbg !367
  br label %while.cond, !dbg !357, !llvm.loop !369

while.end:                                        ; preds = %land.end
    #dbg_declare(ptr %length, !371, !DIExpression(), !372)
  store i32 0, ptr %length, align 4, !dbg !372
  br label %while.cond4, !dbg !373

while.cond4:                                      ; preds = %if.end, %while.end
  %call5 = call ptr @__ctype_b_loc() #9, !dbg !374
  %10 = load ptr, ptr %call5, align 8, !dbg !374
  %11 = load ptr, ptr %p, align 8, !dbg !375
  %12 = load i8, ptr %11, align 1, !dbg !376
  %conv6 = zext i8 %12 to i32, !dbg !374
  %idxprom7 = sext i32 %conv6 to i64, !dbg !374
  %arrayidx8 = getelementptr inbounds i16, ptr %10, i64 %idxprom7, !dbg !374
  %13 = load i16, ptr %arrayidx8, align 2, !dbg !374
  %conv9 = zext i16 %13 to i32, !dbg !374
  %and10 = and i32 %conv9, 1024, !dbg !374
  %tobool11 = icmp ne i32 %and10, 0, !dbg !373
  br i1 %tobool11, label %while.body12, label %while.end21, !dbg !373

while.body12:                                     ; preds = %while.cond4
  %14 = load i32, ptr %length, align 4, !dbg !377
  %cmp13 = icmp slt i32 %14, 23, !dbg !380
  br i1 %cmp13, label %if.then, label %if.end, !dbg !380

if.then:                                          ; preds = %while.body12
  %15 = load ptr, ptr %p, align 8, !dbg !381
  %16 = load i8, ptr %15, align 1, !dbg !383
  %conv15 = zext i8 %16 to i32, !dbg !384
  %call16 = call i32 @tolower(i32 noundef %conv15) #8, !dbg !385
  %conv17 = trunc i32 %call16 to i8, !dbg !386
  %17 = load ptr, ptr %word.addr, align 8, !dbg !387
  %18 = load i32, ptr %length, align 4, !dbg !388
  %inc = add nsw i32 %18, 1, !dbg !388
  store i32 %inc, ptr %length, align 4, !dbg !388
  %idxprom18 = sext i32 %18 to i64, !dbg !387
  %arrayidx19 = getelementptr inbounds i8, ptr %17, i64 %idxprom18, !dbg !387
  store i8 %conv17, ptr %arrayidx19, align 1, !dbg !389
  br label %if.end, !dbg !390

if.end:                                           ; preds = %if.then, %while.body12
  %19 = load ptr, ptr %p, align 8, !dbg !391
  %incdec.ptr20 = getelementptr inbounds nuw i8, ptr %19, i32 1, !dbg !391
  store ptr %incdec.ptr20, ptr %p, align 8, !dbg !391
  br label %while.cond4, !dbg !373, !llvm.loop !392

while.end21:                                      ; preds = %while.cond4
  %20 = load ptr, ptr %word.addr, align 8, !dbg !394
  %21 = load i32, ptr %length, align 4, !dbg !395
  %idxprom22 = sext i32 %21 to i64, !dbg !394
  %arrayidx23 = getelementptr inbounds i8, ptr %20, i64 %idxprom22, !dbg !394
  store i8 0, ptr %arrayidx23, align 1, !dbg !396
  %22 = load ptr, ptr %p, align 8, !dbg !397
  %23 = load ptr, ptr %text.addr, align 8, !dbg !398
  store ptr %22, ptr %23, align 8, !dbg !399
  %24 = load i32, ptr %length, align 4, !dbg !400
  ret i32 %24, !dbg !401
}

; Function Attrs: noinline nounwind uwtable
define internal i32 @table_add(ptr noundef %table, ptr noundef %word, i32 noundef %position) #0 !dbg !402 {
entry:
  %retval = alloca i32, align 4
  %table.addr = alloca ptr, align 8
  %word.addr = alloca ptr, align 8
  %position.addr = alloca i32, align 4
  %index = alloca i32, align 4
  %probe = alloca i32, align 4
  %slot = alloca ptr, align 8
  store ptr %table, ptr %table.addr, align 8
    #dbg_declare(ptr %table.addr, !405, !DIExpression(), !406)
  store ptr %word, ptr %word.addr, align 8
    #dbg_declare(ptr %word.addr, !407, !DIExpression(), !408)
  store i32 %position, ptr %position.addr, align 4
    #dbg_declare(ptr %position.addr, !409, !DIExpression(), !410)
    #dbg_declare(ptr %index, !411, !DIExpression(), !412)
  %0 = load ptr, ptr %word.addr, align 8, !dbg !413
  %call = call i32 @hash_word(ptr noundef %0), !dbg !414
  %rem = urem i32 %call, 256, !dbg !415
  store i32 %rem, ptr %index, align 4, !dbg !412
    #dbg_declare(ptr %probe, !416, !DIExpression(), !418)
  store i32 0, ptr %probe, align 4, !dbg !418
  br label %for.cond, !dbg !419

for.cond:                                         ; preds = %for.inc, %entry
  %1 = load i32, ptr %probe, align 4, !dbg !420
  %cmp = icmp slt i32 %1, 256, !dbg !422
  br i1 %cmp, label %for.body, label %for.end, !dbg !423

for.body:                                         ; preds = %for.cond
    #dbg_declare(ptr %slot, !424, !DIExpression(), !426)
  %2 = load ptr, ptr %table.addr, align 8, !dbg !427
  %slots = getelementptr inbounds nuw %struct.table, ptr %2, i32 0, i32 0, !dbg !428
  %3 = load i32, ptr %index, align 4, !dbg !429
  %idxprom = zext i32 %3 to i64, !dbg !427
  %arrayidx = getelementptr inbounds nuw [256 x %struct.entry], ptr %slots, i64 0, i64 %idxprom, !dbg !427
  store ptr %arrayidx, ptr %slot, align 8, !dbg !426
  %4 = load ptr, ptr %slot, align 8, !dbg !430
  %count = getelementptr inbounds nuw %struct.entry, ptr %4, i32 0, i32 1, !dbg !432
  %5 = load i32, ptr %count, align 4, !dbg !432
  %cmp1 = icmp eq i32 %5, 0, !dbg !433
  br i1 %cmp1, label %if.then, label %if.end, !dbg !433

if.then:                                          ; preds = %for.body
  %6 = load ptr, ptr %slot, align 8, !dbg !434
  %word2 = getelementptr inbounds nuw %struct.entry, ptr %6, i32 0, i32 0, !dbg !436
  %arraydecay = getelementptr inbounds [24 x i8], ptr %word2, i64 0, i64 0, !dbg !434
  %7 = load ptr, ptr %word.addr, align 8, !dbg !437
  %call3 = call ptr @strncpy(ptr noundef %arraydecay, ptr noundef %7, i64 noundef 23) #7, !dbg !438
  %8 = load ptr, ptr %slot, align 8, !dbg !439
  %count4 = getelementptr inbounds nuw %struct.entry, ptr %8, i32 0, i32 1, !dbg !440
  store i32 1, ptr %count4, align 4, !dbg !441
  %9 = load i32, ptr %position.addr, align 4, !dbg !442
  %10 = load ptr, ptr %slot, align 8, !dbg !443
  %first_seen = getelementptr inbounds nuw %struct.entry, ptr %10, i32 0, i32 2, !dbg !444
  store i32 %9, ptr %first_seen, align 4, !dbg !445
  %11 = load ptr, ptr %table.addr, align 8, !dbg !446
  %used = getelementptr inbounds nuw %struct.table, ptr %11, i32 0, i32 1, !dbg !447
  %12 = load i32, ptr %used, align 4, !dbg !448
  %inc = add nsw i32 %12, 1, !dbg !448
  store i32 %inc, ptr %used, align 4, !dbg !448
  store i32 1, ptr %retval, align 4, !dbg !449
  br label %return, !dbg !449

if.end:                                           ; preds = %for.body
  %13 = load ptr, ptr %slot, align 8, !dbg !450
  %word5 = getelementptr inbounds nuw %struct.entry, ptr %13, i32 0, i32 0, !dbg !452
  %arraydecay6 = getelementptr inbounds [24 x i8], ptr %word5, i64 0, i64 0, !dbg !450
  %14 = load ptr, ptr %word.addr, align 8, !dbg !453
  %call7 = call i32 @strcmp(ptr noundef %arraydecay6, ptr noundef %14) #8, !dbg !454
  %cmp8 = icmp eq i32 %call7, 0, !dbg !455
  br i1 %cmp8, label %if.then9, label %if.end12, !dbg !455

if.then9:                                         ; preds = %if.end
  %15 = load ptr, ptr %slot, align 8, !dbg !456
  %count10 = getelementptr inbounds nuw %struct.entry, ptr %15, i32 0, i32 1, !dbg !458
  %16 = load i32, ptr %count10, align 4, !dbg !459
  %inc11 = add nsw i32 %16, 1, !dbg !459
  store i32 %inc11, ptr %count10, align 4, !dbg !459
  store i32 0, ptr %retval, align 4, !dbg !460
  br label %return, !dbg !460

if.end12:                                         ; preds = %if.end
  %17 = load i32, ptr %index, align 4, !dbg !461
  %add = add i32 %17, 1, !dbg !462
  %rem13 = urem i32 %add, 256, !dbg !463
  store i32 %rem13, ptr %index, align 4, !dbg !464
  br label %for.inc, !dbg !465

for.inc:                                          ; preds = %if.end12
  %18 = load i32, ptr %probe, align 4, !dbg !466
  %inc14 = add nsw i32 %18, 1, !dbg !466
  store i32 %inc14, ptr %probe, align 4, !dbg !466
  br label %for.cond, !dbg !467, !llvm.loop !468

for.end:                                          ; preds = %for.cond
  store i32 -1, ptr %retval, align 4, !dbg !470
  br label %return, !dbg !470

return:                                           ; preds = %for.end, %if.then9, %if.then
  %19 = load i32, ptr %retval, align 4, !dbg !471
  ret i32 %19, !dbg !471
}

; Function Attrs: nounwind
declare i32 @fprintf(ptr noundef, ptr noundef, ...) #3

; Function Attrs: nounwind willreturn memory(none)
declare ptr @__ctype_b_loc() #4

; Function Attrs: nounwind willreturn memory(read)
declare i32 @tolower(i32 noundef) #5

; Function Attrs: noinline nounwind uwtable
define internal i32 @hash_word(ptr noundef %word) #0 !dbg !472 {
entry:
  %word.addr = alloca ptr, align 8
  %hash = alloca i32, align 4
  %p = alloca ptr, align 8
  store ptr %word, ptr %word.addr, align 8
    #dbg_declare(ptr %word.addr, !475, !DIExpression(), !476)
    #dbg_declare(ptr %hash, !477, !DIExpression(), !478)
  store i32 -2128831035, ptr %hash, align 4, !dbg !478
    #dbg_declare(ptr %p, !479, !DIExpression(), !481)
  %0 = load ptr, ptr %word.addr, align 8, !dbg !482
  store ptr %0, ptr %p, align 8, !dbg !481
  br label %for.cond, !dbg !483

for.cond:                                         ; preds = %for.inc, %entry
  %1 = load ptr, ptr %p, align 8, !dbg !484
  %2 = load i8, ptr %1, align 1, !dbg !486
  %conv = sext i8 %2 to i32, !dbg !486
  %cmp = icmp ne i32 %conv, 0, !dbg !487
  br i1 %cmp, label %for.body, label %for.end, !dbg !488

for.body:                                         ; preds = %for.cond
  %3 = load ptr, ptr %p, align 8, !dbg !489
  %4 = load i8, ptr %3, align 1, !dbg !491
  %conv2 = zext i8 %4 to i32, !dbg !492
  %5 = load i32, ptr %hash, align 4, !dbg !493
  %xor = xor i32 %5, %conv2, !dbg !493
  store i32 %xor, ptr %hash, align 4, !dbg !493
  %6 = load i32, ptr %hash, align 4, !dbg !494
  %mul = mul i32 %6, 16777619, !dbg !494
  store i32 %mul, ptr %hash, align 4, !dbg !494
  br label %for.inc, !dbg !495

for.inc:                                          ; preds = %for.body
  %7 = load ptr, ptr %p, align 8, !dbg !496
  %incdec.ptr = getelementptr inbounds nuw i8, ptr %7, i32 1, !dbg !496
  store ptr %incdec.ptr, ptr %p, align 8, !dbg !496
  br label %for.cond, !dbg !497, !llvm.loop !498

for.end:                                          ; preds = %for.cond
  %8 = load i32, ptr %hash, align 4, !dbg !500
  ret i32 %8, !dbg !501
}

; Function Attrs: nounwind
declare ptr @strncpy(ptr noundef, ptr noundef, i64 noundef) #3

; Function Attrs: nounwind willreturn memory(read)
declare i32 @strcmp(ptr noundef, ptr noundef) #5

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #6

declare void @qsort(ptr noundef, i64 noundef, i64 noundef, ptr noundef) #1

; Function Attrs: noinline nounwind uwtable
define internal i32 @by_count(ptr noundef %a, ptr noundef %b) #0 !dbg !502 {
entry:
  %retval = alloca i32, align 4
  %a.addr = alloca ptr, align 8
  %b.addr = alloca ptr, align 8
  %x = alloca ptr, align 8
  %y = alloca ptr, align 8
  store ptr %a, ptr %a.addr, align 8
    #dbg_declare(ptr %a.addr, !507, !DIExpression(), !508)
  store ptr %b, ptr %b.addr, align 8
    #dbg_declare(ptr %b.addr, !509, !DIExpression(), !510)
    #dbg_declare(ptr %x, !511, !DIExpression(), !512)
  %0 = load ptr, ptr %a.addr, align 8, !dbg !513
  store ptr %0, ptr %x, align 8, !dbg !512
    #dbg_declare(ptr %y, !514, !DIExpression(), !515)
  %1 = load ptr, ptr %b.addr, align 8, !dbg !516
  store ptr %1, ptr %y, align 8, !dbg !515
  %2 = load ptr, ptr %x, align 8, !dbg !517
  %count = getelementptr inbounds nuw %struct.entry, ptr %2, i32 0, i32 1, !dbg !519
  %3 = load i32, ptr %count, align 4, !dbg !519
  %4 = load ptr, ptr %y, align 8, !dbg !520
  %count1 = getelementptr inbounds nuw %struct.entry, ptr %4, i32 0, i32 1, !dbg !521
  %5 = load i32, ptr %count1, align 4, !dbg !521
  %cmp = icmp ne i32 %3, %5, !dbg !522
  br i1 %cmp, label %if.then, label %if.end, !dbg !522

if.then:                                          ; preds = %entry
  %6 = load ptr, ptr %y, align 8, !dbg !523
  %count2 = getelementptr inbounds nuw %struct.entry, ptr %6, i32 0, i32 1, !dbg !525
  %7 = load i32, ptr %count2, align 4, !dbg !525
  %8 = load ptr, ptr %x, align 8, !dbg !526
  %count3 = getelementptr inbounds nuw %struct.entry, ptr %8, i32 0, i32 1, !dbg !527
  %9 = load i32, ptr %count3, align 4, !dbg !527
  %sub = sub nsw i32 %7, %9, !dbg !528
  store i32 %sub, ptr %retval, align 4, !dbg !529
  br label %return, !dbg !529

if.end:                                           ; preds = %entry
  %10 = load ptr, ptr %x, align 8, !dbg !530
  %first_seen = getelementptr inbounds nuw %struct.entry, ptr %10, i32 0, i32 2, !dbg !531
  %11 = load i32, ptr %first_seen, align 4, !dbg !531
  %12 = load ptr, ptr %y, align 8, !dbg !532
  %first_seen4 = getelementptr inbounds nuw %struct.entry, ptr %12, i32 0, i32 2, !dbg !533
  %13 = load i32, ptr %first_seen4, align 4, !dbg !533
  %sub5 = sub nsw i32 %11, %13, !dbg !534
  store i32 %sub5, ptr %retval, align 4, !dbg !535
  br label %return, !dbg !535

return:                                           ; preds = %if.end, %if.then
  %14 = load i32, ptr %retval, align 4, !dbg !536
  ret i32 %14, !dbg !536
}

; Function Attrs: noinline nounwind uwtable
define internal void @print_bar(i32 noundef %count, i32 noundef %widest) #0 !dbg !537 {
entry:
  %count.addr = alloca i32, align 4
  %widest.addr = alloca i32, align 4
  %width = alloca i32, align 4
  %i = alloca i32, align 4
  store i32 %count, ptr %count.addr, align 4
    #dbg_declare(ptr %count.addr, !540, !DIExpression(), !541)
  store i32 %widest, ptr %widest.addr, align 4
    #dbg_declare(ptr %widest.addr, !542, !DIExpression(), !543)
    #dbg_declare(ptr %width, !544, !DIExpression(), !545)
  %0 = load i32, ptr %widest.addr, align 4, !dbg !546
  %cmp = icmp sgt i32 %0, 0, !dbg !547
  br i1 %cmp, label %cond.true, label %cond.false, !dbg !546

cond.true:                                        ; preds = %entry
  %1 = load i32, ptr %count.addr, align 4, !dbg !548
  %mul = mul nsw i32 %1, 30, !dbg !549
  %2 = load i32, ptr %widest.addr, align 4, !dbg !550
  %div = sdiv i32 %mul, %2, !dbg !551
  br label %cond.end, !dbg !546

cond.false:                                       ; preds = %entry
  br label %cond.end, !dbg !546

cond.end:                                         ; preds = %cond.false, %cond.true
  %cond = phi i32 [ %div, %cond.true ], [ 0, %cond.false ], !dbg !546
  store i32 %cond, ptr %width, align 4, !dbg !545
    #dbg_declare(ptr %i, !552, !DIExpression(), !554)
  store i32 0, ptr %i, align 4, !dbg !554
  br label %for.cond, !dbg !555

for.cond:                                         ; preds = %for.inc, %cond.end
  %3 = load i32, ptr %i, align 4, !dbg !556
  %4 = load i32, ptr %width, align 4, !dbg !558
  %cmp1 = icmp slt i32 %3, %4, !dbg !559
  br i1 %cmp1, label %for.body, label %for.end, !dbg !560

for.body:                                         ; preds = %for.cond
  %call = call i32 @putchar(i32 noundef 35), !dbg !561
  br label %for.inc, !dbg !563

for.inc:                                          ; preds = %for.body
  %5 = load i32, ptr %i, align 4, !dbg !564
  %inc = add nsw i32 %5, 1, !dbg !564
  store i32 %inc, ptr %i, align 4, !dbg !564
  br label %for.cond, !dbg !565, !llvm.loop !566

for.end:                                          ; preds = %for.cond
  %call2 = call i32 @putchar(i32 noundef 10), !dbg !568
  ret void, !dbg !569
}

; Function Attrs: noinline nounwind uwtable
define internal ptr @longest(ptr noundef %entries, i32 noundef %n) #0 !dbg !570 {
entry:
  %entries.addr = alloca ptr, align 8
  %n.addr = alloca i32, align 4
  %best = alloca ptr, align 8
  %best_length = alloca i64, align 8
  %i = alloca i32, align 4
  %length = alloca i64, align 8
  store ptr %entries, ptr %entries.addr, align 8
    #dbg_declare(ptr %entries.addr, !573, !DIExpression(), !574)
  store i32 %n, ptr %n.addr, align 4
    #dbg_declare(ptr %n.addr, !575, !DIExpression(), !576)
    #dbg_declare(ptr %best, !577, !DIExpression(), !578)
  store ptr null, ptr %best, align 8, !dbg !578
    #dbg_declare(ptr %best_length, !579, !DIExpression(), !580)
  store i64 0, ptr %best_length, align 8, !dbg !580
    #dbg_declare(ptr %i, !581, !DIExpression(), !583)
  store i32 0, ptr %i, align 4, !dbg !583
  br label %for.cond, !dbg !584

for.cond:                                         ; preds = %for.inc, %entry
  %0 = load i32, ptr %i, align 4, !dbg !585
  %1 = load i32, ptr %n.addr, align 4, !dbg !587
  %cmp = icmp slt i32 %0, %1, !dbg !588
  br i1 %cmp, label %for.body, label %for.end, !dbg !589

for.body:                                         ; preds = %for.cond
    #dbg_declare(ptr %length, !590, !DIExpression(), !592)
  %2 = load ptr, ptr %entries.addr, align 8, !dbg !593
  %3 = load i32, ptr %i, align 4, !dbg !594
  %idxprom = sext i32 %3 to i64, !dbg !593
  %arrayidx = getelementptr inbounds %struct.entry, ptr %2, i64 %idxprom, !dbg !593
  %word = getelementptr inbounds nuw %struct.entry, ptr %arrayidx, i32 0, i32 0, !dbg !595
  %arraydecay = getelementptr inbounds [24 x i8], ptr %word, i64 0, i64 0, !dbg !593
  %call = call i64 @strlen(ptr noundef %arraydecay) #8, !dbg !596
  store i64 %call, ptr %length, align 8, !dbg !592
  %4 = load i64, ptr %length, align 8, !dbg !597
  %5 = load i64, ptr %best_length, align 8, !dbg !599
  %cmp1 = icmp ugt i64 %4, %5, !dbg !600
  br i1 %cmp1, label %if.then, label %if.end, !dbg !600

if.then:                                          ; preds = %for.body
  %6 = load ptr, ptr %entries.addr, align 8, !dbg !601
  %7 = load i32, ptr %i, align 4, !dbg !603
  %idxprom2 = sext i32 %7 to i64, !dbg !601
  %arrayidx3 = getelementptr inbounds %struct.entry, ptr %6, i64 %idxprom2, !dbg !601
  store ptr %arrayidx3, ptr %best, align 8, !dbg !604
  %8 = load i64, ptr %length, align 8, !dbg !605
  store i64 %8, ptr %best_length, align 8, !dbg !606
  br label %if.end, !dbg !607

if.end:                                           ; preds = %if.then, %for.body
  br label %for.inc, !dbg !608

for.inc:                                          ; preds = %if.end
  %9 = load i32, ptr %i, align 4, !dbg !609
  %inc = add nsw i32 %9, 1, !dbg !609
  store i32 %inc, ptr %i, align 4, !dbg !609
  br label %for.cond, !dbg !610, !llvm.loop !611

for.end:                                          ; preds = %for.cond
  %10 = load ptr, ptr %best, align 8, !dbg !613
  ret ptr %10, !dbg !614
}

; Function Attrs: noinline nounwind uwtable
define internal double @mean_length(ptr noundef %entries, i32 noundef %n) #0 !dbg !615 {
entry:
  %entries.addr = alloca ptr, align 8
  %n.addr = alloca i32, align 4
  %letters = alloca i64, align 8
  %words = alloca i64, align 8
  %i = alloca i32, align 4
  store ptr %entries, ptr %entries.addr, align 8
    #dbg_declare(ptr %entries.addr, !618, !DIExpression(), !619)
  store i32 %n, ptr %n.addr, align 4
    #dbg_declare(ptr %n.addr, !620, !DIExpression(), !621)
    #dbg_declare(ptr %letters, !622, !DIExpression(), !623)
  store i64 0, ptr %letters, align 8, !dbg !623
    #dbg_declare(ptr %words, !624, !DIExpression(), !625)
  store i64 0, ptr %words, align 8, !dbg !625
    #dbg_declare(ptr %i, !626, !DIExpression(), !628)
  store i32 0, ptr %i, align 4, !dbg !628
  br label %for.cond, !dbg !629

for.cond:                                         ; preds = %for.inc, %entry
  %0 = load i32, ptr %i, align 4, !dbg !630
  %1 = load i32, ptr %n.addr, align 4, !dbg !632
  %cmp = icmp slt i32 %0, %1, !dbg !633
  br i1 %cmp, label %for.body, label %for.end, !dbg !634

for.body:                                         ; preds = %for.cond
  %2 = load ptr, ptr %entries.addr, align 8, !dbg !635
  %3 = load i32, ptr %i, align 4, !dbg !637
  %idxprom = sext i32 %3 to i64, !dbg !635
  %arrayidx = getelementptr inbounds %struct.entry, ptr %2, i64 %idxprom, !dbg !635
  %word = getelementptr inbounds nuw %struct.entry, ptr %arrayidx, i32 0, i32 0, !dbg !638
  %arraydecay = getelementptr inbounds [24 x i8], ptr %word, i64 0, i64 0, !dbg !635
  %call = call i64 @strlen(ptr noundef %arraydecay) #8, !dbg !639
  %4 = load ptr, ptr %entries.addr, align 8, !dbg !640
  %5 = load i32, ptr %i, align 4, !dbg !641
  %idxprom1 = sext i32 %5 to i64, !dbg !640
  %arrayidx2 = getelementptr inbounds %struct.entry, ptr %4, i64 %idxprom1, !dbg !640
  %count = getelementptr inbounds nuw %struct.entry, ptr %arrayidx2, i32 0, i32 1, !dbg !642
  %6 = load i32, ptr %count, align 4, !dbg !642
  %conv = sext i32 %6 to i64, !dbg !640
  %mul = mul nsw i64 %call, %conv, !dbg !643
  %7 = load i64, ptr %letters, align 8, !dbg !644
  %add = add nsw i64 %7, %mul, !dbg !644
  store i64 %add, ptr %letters, align 8, !dbg !644
  %8 = load ptr, ptr %entries.addr, align 8, !dbg !645
  %9 = load i32, ptr %i, align 4, !dbg !646
  %idxprom3 = sext i32 %9 to i64, !dbg !645
  %arrayidx4 = getelementptr inbounds %struct.entry, ptr %8, i64 %idxprom3, !dbg !645
  %count5 = getelementptr inbounds nuw %struct.entry, ptr %arrayidx4, i32 0, i32 1, !dbg !647
  %10 = load i32, ptr %count5, align 4, !dbg !647
  %conv6 = sext i32 %10 to i64, !dbg !645
  %11 = load i64, ptr %words, align 8, !dbg !648
  %add7 = add nsw i64 %11, %conv6, !dbg !648
  store i64 %add7, ptr %words, align 8, !dbg !648
  br label %for.inc, !dbg !649

for.inc:                                          ; preds = %for.body
  %12 = load i32, ptr %i, align 4, !dbg !650
  %inc = add nsw i32 %12, 1, !dbg !650
  store i32 %inc, ptr %i, align 4, !dbg !650
  br label %for.cond, !dbg !651, !llvm.loop !652

for.end:                                          ; preds = %for.cond
  %13 = load i64, ptr %words, align 8, !dbg !654
  %cmp8 = icmp sgt i64 %13, 0, !dbg !655
  br i1 %cmp8, label %cond.true, label %cond.false, !dbg !654

cond.true:                                        ; preds = %for.end
  %14 = load i64, ptr %letters, align 8, !dbg !656
  %conv10 = sitofp i64 %14 to double, !dbg !657
  %15 = load i64, ptr %words, align 8, !dbg !658
  %conv11 = sitofp i64 %15 to double, !dbg !659
  %div = fdiv double %conv10, %conv11, !dbg !660
  br label %cond.end, !dbg !654

cond.false:                                       ; preds = %for.end
  br label %cond.end, !dbg !654

cond.end:                                         ; preds = %cond.false, %cond.true
  %cond = phi double [ %div, %cond.true ], [ 0.000000e+00, %cond.false ], !dbg !654
  ret double %cond, !dbg !661
}

; Function Attrs: noinline nounwind uwtable
define internal i32 @singletons(ptr noundef %entries, i32 noundef %n) #0 !dbg !662 {
entry:
  %entries.addr = alloca ptr, align 8
  %n.addr = alloca i32, align 4
  %count = alloca i32, align 4
  %i = alloca i32, align 4
  store ptr %entries, ptr %entries.addr, align 8
    #dbg_declare(ptr %entries.addr, !665, !DIExpression(), !666)
  store i32 %n, ptr %n.addr, align 4
    #dbg_declare(ptr %n.addr, !667, !DIExpression(), !668)
    #dbg_declare(ptr %count, !669, !DIExpression(), !670)
  store i32 0, ptr %count, align 4, !dbg !670
    #dbg_declare(ptr %i, !671, !DIExpression(), !673)
  %0 = load i32, ptr %n.addr, align 4, !dbg !674
  %sub = sub nsw i32 %0, 1, !dbg !675
  store i32 %sub, ptr %i, align 4, !dbg !673
  br label %for.cond, !dbg !676

for.cond:                                         ; preds = %for.inc, %entry
  %1 = load i32, ptr %i, align 4, !dbg !677
  %cmp = icmp sge i32 %1, 0, !dbg !679
  br i1 %cmp, label %land.rhs, label %land.end, !dbg !680

land.rhs:                                         ; preds = %for.cond
  %2 = load ptr, ptr %entries.addr, align 8, !dbg !681
  %3 = load i32, ptr %i, align 4, !dbg !682
  %idxprom = sext i32 %3 to i64, !dbg !681
  %arrayidx = getelementptr inbounds %struct.entry, ptr %2, i64 %idxprom, !dbg !681
  %count1 = getelementptr inbounds nuw %struct.entry, ptr %arrayidx, i32 0, i32 1, !dbg !683
  %4 = load i32, ptr %count1, align 4, !dbg !683
  %cmp2 = icmp eq i32 %4, 1, !dbg !684
  br label %land.end

land.end:                                         ; preds = %land.rhs, %for.cond
  %5 = phi i1 [ false, %for.cond ], [ %cmp2, %land.rhs ], !dbg !685
  br i1 %5, label %for.body, label %for.end, !dbg !686

for.body:                                         ; preds = %land.end
  %6 = load i32, ptr %count, align 4, !dbg !687
  %inc = add nsw i32 %6, 1, !dbg !687
  store i32 %inc, ptr %count, align 4, !dbg !687
  br label %for.inc, !dbg !689

for.inc:                                          ; preds = %for.body
  %7 = load i32, ptr %i, align 4, !dbg !690
  %dec = add nsw i32 %7, -1, !dbg !690
  store i32 %dec, ptr %i, align 4, !dbg !690
  br label %for.cond, !dbg !691, !llvm.loop !692

for.end:                                          ; preds = %land.end
  %8 = load i32, ptr %count, align 4, !dbg !694
  ret i32 %8, !dbg !695
}

declare i32 @putchar(i32 noundef) #1

; Function Attrs: nounwind willreturn memory(read)
declare i64 @strlen(ptr noundef) #5

attributes #0 = { noinline nounwind uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #3 = { nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind willreturn memory(none) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #6 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #7 = { nounwind }
attributes #8 = { nounwind willreturn memory(read) }
attributes #9 = { nounwind willreturn memory(none) }

!llvm.dbg.cu = !{!7}
!llvm.module.flags = !{!100, !101, !102, !103, !104, !105, !106}
!llvm.ident = !{!107}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(name: "table", scope: !2, file: !3, line: 186, type: !96, isLocal: true, isDefinition: true)
!2 = distinct !DISubprogram(name: "main", scope: !3, file: !3, line: 185, type: !4, scopeLine: 185, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !7, retainedNodes: !95)
!3 = !DIFile(filename: "user-programs/word_frequency.c", directory: "/workspace", checksumkind: CSK_MD5, checksum: "afd9b995c56306632b4c51ff31edd173")
!4 = !DISubroutineType(types: !5)
!5 = !{!6}
!6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!7 = distinct !DICompileUnit(language: DW_LANG_C11, file: !8, producer: "clang version 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, enums: !9, retainedTypes: !26, globals: !36, splitDebugInlining: false, nameTableKind: None)
!8 = !DIFile(filename: "/workspace/user-programs/word_frequency.c", directory: "/workspace", checksumkind: CSK_MD5, checksum: "afd9b995c56306632b4c51ff31edd173")
!9 = !{!10}
!10 = !DICompositeType(tag: DW_TAG_enumeration_type, file: !11, line: 46, baseType: !12, size: 32, elements: !13)
!11 = !DIFile(filename: "/usr/include/ctype.h", directory: "", checksumkind: CSK_MD5, checksum: "43fd45dcf96e8fb7d8f14700096497c7")
!12 = !DIBasicType(name: "unsigned int", size: 32, encoding: DW_ATE_unsigned)
!13 = !{!14, !15, !16, !17, !18, !19, !20, !21, !22, !23, !24, !25}
!14 = !DIEnumerator(name: "_ISupper", value: 256)
!15 = !DIEnumerator(name: "_ISlower", value: 512)
!16 = !DIEnumerator(name: "_ISalpha", value: 1024)
!17 = !DIEnumerator(name: "_ISdigit", value: 2048)
!18 = !DIEnumerator(name: "_ISxdigit", value: 4096)
!19 = !DIEnumerator(name: "_ISspace", value: 8192)
!20 = !DIEnumerator(name: "_ISprint", value: 16384)
!21 = !DIEnumerator(name: "_ISgraph", value: 32768)
!22 = !DIEnumerator(name: "_ISblank", value: 1)
!23 = !DIEnumerator(name: "_IScntrl", value: 2)
!24 = !DIEnumerator(name: "_ISpunct", value: 4)
!25 = !DIEnumerator(name: "_ISalnum", value: 8)
!26 = !{!6, !27, !28, !29, !30, !33, !34, !35}
!27 = !DIBasicType(name: "unsigned char", size: 8, encoding: DW_ATE_unsigned_char)
!28 = !DIBasicType(name: "unsigned short", size: 16, encoding: DW_ATE_unsigned)
!29 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!30 = !DIDerivedType(tag: DW_TAG_typedef, name: "size_t", file: !31, line: 18, baseType: !32)
!31 = !DIFile(filename: "/opt/llvm/lib/clang/22/include/__stddef_size_t.h", directory: "", checksumkind: CSK_MD5, checksum: "2c44e821a2b1951cde2eb0fb2e656867")
!32 = !DIBasicType(name: "unsigned long", size: 64, encoding: DW_ATE_unsigned)
!33 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
!34 = !DIBasicType(name: "long", size: 64, encoding: DW_ATE_signed)
!35 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!36 = !{!0, !37, !50, !55, !57, !62, !67, !72, !76, !78, !83, !85, !90}
!37 = !DIGlobalVariableExpression(var: !38, expr: !DIExpression())
!38 = distinct !DIGlobalVariable(name: "entries", scope: !2, file: !3, line: 187, type: !39, isLocal: true, isDefinition: true)
!39 = !DICompositeType(tag: DW_TAG_array_type, baseType: !40, size: 65536, elements: !48)
!40 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "entry", file: !3, line: 12, size: 256, elements: !41)
!41 = !{!42, !46, !47}
!42 = !DIDerivedType(tag: DW_TAG_member, name: "word", scope: !40, file: !3, line: 13, baseType: !43, size: 192)
!43 = !DICompositeType(tag: DW_TAG_array_type, baseType: !29, size: 192, elements: !44)
!44 = !{!45}
!45 = !DISubrange(count: 24)
!46 = !DIDerivedType(tag: DW_TAG_member, name: "count", scope: !40, file: !3, line: 14, baseType: !6, size: 32, offset: 192)
!47 = !DIDerivedType(tag: DW_TAG_member, name: "first_seen", scope: !40, file: !3, line: 15, baseType: !6, size: 32, offset: 224)
!48 = !{!49}
!49 = !DISubrange(count: 256)
!50 = !DIGlobalVariableExpression(var: !51, expr: !DIExpression())
!51 = distinct !DIGlobalVariable(scope: null, file: !3, line: 192, type: !52, isLocal: true, isDefinition: true)
!52 = !DICompositeType(tag: DW_TAG_array_type, baseType: !29, size: 32, elements: !53)
!53 = !{!54}
!54 = !DISubrange(count: 4)
!55 = !DIGlobalVariableExpression(var: !56, expr: !DIExpression())
!56 = distinct !DIGlobalVariable(scope: null, file: !3, line: 193, type: !52, isLocal: true, isDefinition: true)
!57 = !DIGlobalVariableExpression(var: !58, expr: !DIExpression())
!58 = distinct !DIGlobalVariable(scope: null, file: !3, line: 194, type: !59, isLocal: true, isDefinition: true)
!59 = !DICompositeType(tag: DW_TAG_array_type, baseType: !29, size: 144, elements: !60)
!60 = !{!61}
!61 = !DISubrange(count: 18)
!62 = !DIGlobalVariableExpression(var: !63, expr: !DIExpression())
!63 = distinct !DIGlobalVariable(scope: null, file: !3, line: 102, type: !64, isLocal: true, isDefinition: true)
!64 = !DICompositeType(tag: DW_TAG_array_type, baseType: !29, size: 184, elements: !65)
!65 = !{!66}
!66 = !DISubrange(count: 23)
!67 = !DIGlobalVariableExpression(var: !68, expr: !DIExpression())
!68 = distinct !DIGlobalVariable(scope: null, file: !3, line: 24, type: !69, isLocal: true, isDefinition: true)
!69 = !DICompositeType(tag: DW_TAG_array_type, baseType: !29, size: 2280, elements: !70)
!70 = !{!71}
!71 = !DISubrange(count: 285)
!72 = !DIGlobalVariableExpression(var: !73, expr: !DIExpression())
!73 = distinct !DIGlobalVariable(name: "passage", scope: !7, file: !3, line: 23, type: !74, isLocal: true, isDefinition: true)
!74 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !75, size: 64)
!75 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !29)
!76 = !DIGlobalVariableExpression(var: !77, expr: !DIExpression())
!77 = distinct !DIGlobalVariable(scope: null, file: !3, line: 172, type: !64, isLocal: true, isDefinition: true)
!78 = !DIGlobalVariableExpression(var: !79, expr: !DIExpression())
!79 = distinct !DIGlobalVariable(scope: null, file: !3, line: 174, type: !80, isLocal: true, isDefinition: true)
!80 = !DICompositeType(tag: DW_TAG_array_type, baseType: !29, size: 88, elements: !81)
!81 = !{!82}
!82 = !DISubrange(count: 11)
!83 = !DIGlobalVariableExpression(var: !84, expr: !DIExpression())
!84 = distinct !DIGlobalVariable(scope: null, file: !3, line: 179, type: !59, isLocal: true, isDefinition: true)
!85 = !DIGlobalVariableExpression(var: !86, expr: !DIExpression())
!86 = distinct !DIGlobalVariable(scope: null, file: !3, line: 181, type: !87, isLocal: true, isDefinition: true)
!87 = !DICompositeType(tag: DW_TAG_array_type, baseType: !29, size: 216, elements: !88)
!88 = !{!89}
!89 = !DISubrange(count: 27)
!90 = !DIGlobalVariableExpression(var: !91, expr: !DIExpression())
!91 = distinct !DIGlobalVariable(scope: null, file: !3, line: 182, type: !92, isLocal: true, isDefinition: true)
!92 = !DICompositeType(tag: DW_TAG_array_type, baseType: !29, size: 168, elements: !93)
!93 = !{!94}
!94 = !DISubrange(count: 21)
!95 = !{}
!96 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "table", file: !3, line: 18, size: 65568, elements: !97)
!97 = !{!98, !99}
!98 = !DIDerivedType(tag: DW_TAG_member, name: "slots", scope: !96, file: !3, line: 19, baseType: !39, size: 65536)
!99 = !DIDerivedType(tag: DW_TAG_member, name: "used", scope: !96, file: !3, line: 20, baseType: !6, size: 32, offset: 65536)
!100 = !{i32 7, !"Dwarf Version", i32 5}
!101 = !{i32 2, !"Debug Info Version", i32 3}
!102 = !{i32 1, !"wchar_size", i32 4}
!103 = !{i32 8, !"PIC Level", i32 2}
!104 = !{i32 7, !"PIE Level", i32 2}
!105 = !{i32 7, !"uwtable", i32 2}
!106 = !{i32 7, !"frame-pointer", i32 2}
!107 = !{!"clang version 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)"}
!108 = !DILocation(line: 188, column: 5, scope: !2)
!109 = !DILocalVariable(name: "total", scope: !2, file: !3, line: 189, type: !6)
!110 = !DILocation(line: 189, column: 9, scope: !2)
!111 = !DILocation(line: 189, column: 37, scope: !2)
!112 = !DILocation(line: 189, column: 17, scope: !2)
!113 = !DILocalVariable(name: "n", scope: !2, file: !3, line: 190, type: !6)
!114 = !DILocation(line: 190, column: 9, scope: !2)
!115 = !DILocation(line: 190, column: 13, scope: !2)
!116 = !DILocation(line: 191, column: 21, scope: !2)
!117 = !DILocation(line: 191, column: 24, scope: !2)
!118 = !DILocation(line: 191, column: 5, scope: !2)
!119 = !DILocalVariable(name: "foxes", scope: !2, file: !3, line: 192, type: !6)
!120 = !DILocation(line: 192, column: 9, scope: !2)
!121 = !DILocation(line: 192, column: 17, scope: !2)
!122 = !DILocalVariable(name: "cats", scope: !2, file: !3, line: 193, type: !6)
!123 = !DILocation(line: 193, column: 9, scope: !2)
!124 = !DILocation(line: 193, column: 16, scope: !2)
!125 = !DILocation(line: 194, column: 34, scope: !2)
!126 = !DILocation(line: 194, column: 41, scope: !2)
!127 = !DILocation(line: 194, column: 5, scope: !2)
!128 = !DILocation(line: 195, column: 12, scope: !2)
!129 = !DILocation(line: 195, column: 18, scope: !2)
!130 = !DILocation(line: 195, column: 22, scope: !2)
!131 = !DILocation(line: 195, column: 25, scope: !2)
!132 = !DILocation(line: 195, column: 30, scope: !2)
!133 = !DILocation(line: 0, scope: !2)
!134 = !DILocation(line: 195, column: 5, scope: !2)
!135 = distinct !DISubprogram(name: "table_init", scope: !3, file: !3, line: 39, type: !136, scopeLine: 39, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!136 = !DISubroutineType(types: !137)
!137 = !{null, !138}
!138 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !96, size: 64)
!139 = !DILocalVariable(name: "table", arg: 1, scope: !135, file: !3, line: 39, type: !138)
!140 = !DILocation(line: 39, column: 38, scope: !135)
!141 = !DILocation(line: 40, column: 12, scope: !135)
!142 = !DILocation(line: 40, column: 5, scope: !135)
!143 = !DILocation(line: 41, column: 1, scope: !135)
!144 = distinct !DISubprogram(name: "count_words", scope: !3, file: !3, line: 97, type: !145, scopeLine: 97, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!145 = !DISubroutineType(types: !146)
!146 = !{!6, !138, !74}
!147 = !DILocalVariable(name: "table", arg: 1, scope: !144, file: !3, line: 97, type: !138)
!148 = !DILocation(line: 97, column: 38, scope: !144)
!149 = !DILocalVariable(name: "text", arg: 2, scope: !144, file: !3, line: 97, type: !74)
!150 = !DILocation(line: 97, column: 57, scope: !144)
!151 = !DILocalVariable(name: "word", scope: !144, file: !3, line: 98, type: !43)
!152 = !DILocation(line: 98, column: 10, scope: !144)
!153 = !DILocalVariable(name: "position", scope: !144, file: !3, line: 99, type: !6)
!154 = !DILocation(line: 99, column: 9, scope: !144)
!155 = !DILocation(line: 100, column: 5, scope: !144)
!156 = !DILocation(line: 100, column: 29, scope: !144)
!157 = !DILocation(line: 100, column: 12, scope: !144)
!158 = !DILocation(line: 100, column: 35, scope: !144)
!159 = !DILocation(line: 101, column: 23, scope: !160)
!160 = distinct !DILexicalBlock(scope: !161, file: !3, line: 101, column: 13)
!161 = distinct !DILexicalBlock(scope: !144, file: !3, line: 100, column: 40)
!162 = !DILocation(line: 101, column: 30, scope: !160)
!163 = !DILocation(line: 101, column: 36, scope: !160)
!164 = !DILocation(line: 101, column: 13, scope: !160)
!165 = !DILocation(line: 101, column: 46, scope: !160)
!166 = !DILocation(line: 102, column: 21, scope: !167)
!167 = distinct !DILexicalBlock(scope: !160, file: !3, line: 101, column: 51)
!168 = !DILocation(line: 102, column: 56, scope: !167)
!169 = !DILocation(line: 102, column: 13, scope: !167)
!170 = !DILocation(line: 103, column: 13, scope: !167)
!171 = !DILocation(line: 105, column: 17, scope: !161)
!172 = distinct !{!172, !155, !173, !174}
!173 = !DILocation(line: 106, column: 5, scope: !144)
!174 = !{!"llvm.loop.mustprogress"}
!175 = !DILocation(line: 107, column: 12, scope: !144)
!176 = !DILocation(line: 107, column: 5, scope: !144)
!177 = distinct !DISubprogram(name: "collect", scope: !3, file: !3, line: 120, type: !178, scopeLine: 120, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!178 = !DISubroutineType(types: !179)
!179 = !{!6, !180, !182}
!180 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !181, size: 64)
!181 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !96)
!182 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !40, size: 64)
!183 = !DILocalVariable(name: "table", arg: 1, scope: !177, file: !3, line: 120, type: !180)
!184 = !DILocation(line: 120, column: 40, scope: !177)
!185 = !DILocalVariable(name: "out", arg: 2, scope: !177, file: !3, line: 120, type: !182)
!186 = !DILocation(line: 120, column: 61, scope: !177)
!187 = !DILocalVariable(name: "n", scope: !177, file: !3, line: 121, type: !6)
!188 = !DILocation(line: 121, column: 9, scope: !177)
!189 = !DILocalVariable(name: "i", scope: !190, file: !3, line: 122, type: !6)
!190 = distinct !DILexicalBlock(scope: !177, file: !3, line: 122, column: 5)
!191 = !DILocation(line: 122, column: 14, scope: !190)
!192 = !DILocation(line: 122, column: 10, scope: !190)
!193 = !DILocation(line: 122, column: 21, scope: !194)
!194 = distinct !DILexicalBlock(scope: !190, file: !3, line: 122, column: 5)
!195 = !DILocation(line: 122, column: 23, scope: !194)
!196 = !DILocation(line: 122, column: 5, scope: !190)
!197 = !DILocation(line: 123, column: 13, scope: !198)
!198 = distinct !DILexicalBlock(scope: !199, file: !3, line: 123, column: 13)
!199 = distinct !DILexicalBlock(scope: !194, file: !3, line: 122, column: 42)
!200 = !DILocation(line: 123, column: 20, scope: !198)
!201 = !DILocation(line: 123, column: 26, scope: !198)
!202 = !DILocation(line: 123, column: 29, scope: !198)
!203 = !DILocation(line: 123, column: 35, scope: !198)
!204 = !DILocation(line: 124, column: 13, scope: !205)
!205 = distinct !DILexicalBlock(scope: !198, file: !3, line: 123, column: 40)
!206 = !DILocation(line: 124, column: 18, scope: !205)
!207 = !DILocation(line: 124, column: 24, scope: !205)
!208 = !DILocation(line: 124, column: 31, scope: !205)
!209 = !DILocation(line: 124, column: 37, scope: !205)
!210 = !DILocation(line: 125, column: 9, scope: !205)
!211 = !DILocation(line: 126, column: 5, scope: !199)
!212 = !DILocation(line: 122, column: 38, scope: !194)
!213 = !DILocation(line: 122, column: 5, scope: !194)
!214 = distinct !{!214, !196, !215, !174}
!215 = !DILocation(line: 126, column: 5, scope: !190)
!216 = !DILocation(line: 127, column: 11, scope: !177)
!217 = !DILocation(line: 127, column: 24, scope: !177)
!218 = !DILocation(line: 127, column: 16, scope: !177)
!219 = !DILocation(line: 127, column: 5, scope: !177)
!220 = !DILocation(line: 128, column: 12, scope: !177)
!221 = !DILocation(line: 128, column: 5, scope: !177)
!222 = distinct !DISubprogram(name: "report", scope: !3, file: !3, line: 170, type: !223, scopeLine: 170, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!223 = !DISubroutineType(types: !224)
!224 = !{null, !225, !6, !6}
!225 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !226, size: 64)
!226 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !40)
!227 = !DILocalVariable(name: "entries", arg: 1, scope: !222, file: !3, line: 170, type: !225)
!228 = !DILocation(line: 170, column: 40, scope: !222)
!229 = !DILocalVariable(name: "n", arg: 2, scope: !222, file: !3, line: 170, type: !6)
!230 = !DILocation(line: 170, column: 53, scope: !222)
!231 = !DILocalVariable(name: "total", arg: 3, scope: !222, file: !3, line: 170, type: !6)
!232 = !DILocation(line: 170, column: 60, scope: !222)
!233 = !DILocalVariable(name: "shown", scope: !222, file: !3, line: 171, type: !6)
!234 = !DILocation(line: 171, column: 9, scope: !222)
!235 = !DILocation(line: 171, column: 17, scope: !222)
!236 = !DILocation(line: 171, column: 19, scope: !222)
!237 = !DILocation(line: 171, column: 33, scope: !222)
!238 = !DILocation(line: 172, column: 39, scope: !222)
!239 = !DILocation(line: 172, column: 46, scope: !222)
!240 = !DILocation(line: 172, column: 5, scope: !222)
!241 = !DILocalVariable(name: "i", scope: !242, file: !3, line: 173, type: !6)
!242 = distinct !DILexicalBlock(scope: !222, file: !3, line: 173, column: 5)
!243 = !DILocation(line: 173, column: 14, scope: !242)
!244 = !DILocation(line: 173, column: 10, scope: !242)
!245 = !DILocation(line: 173, column: 21, scope: !246)
!246 = distinct !DILexicalBlock(scope: !242, file: !3, line: 173, column: 5)
!247 = !DILocation(line: 173, column: 25, scope: !246)
!248 = !DILocation(line: 173, column: 23, scope: !246)
!249 = !DILocation(line: 173, column: 5, scope: !242)
!250 = !DILocation(line: 174, column: 30, scope: !251)
!251 = distinct !DILexicalBlock(scope: !246, file: !3, line: 173, column: 37)
!252 = !DILocation(line: 174, column: 38, scope: !251)
!253 = !DILocation(line: 174, column: 41, scope: !251)
!254 = !DILocation(line: 174, column: 47, scope: !251)
!255 = !DILocation(line: 174, column: 55, scope: !251)
!256 = !DILocation(line: 174, column: 58, scope: !251)
!257 = !DILocation(line: 174, column: 9, scope: !251)
!258 = !DILocation(line: 175, column: 19, scope: !251)
!259 = !DILocation(line: 175, column: 27, scope: !251)
!260 = !DILocation(line: 175, column: 30, scope: !251)
!261 = !DILocation(line: 175, column: 37, scope: !251)
!262 = !DILocation(line: 175, column: 48, scope: !251)
!263 = !DILocation(line: 175, column: 9, scope: !251)
!264 = !DILocation(line: 176, column: 5, scope: !251)
!265 = !DILocation(line: 173, column: 33, scope: !246)
!266 = !DILocation(line: 173, column: 5, scope: !246)
!267 = distinct !{!267, !249, !268, !174}
!268 = !DILocation(line: 176, column: 5, scope: !242)
!269 = !DILocalVariable(name: "word", scope: !222, file: !3, line: 177, type: !225)
!270 = !DILocation(line: 177, column: 25, scope: !222)
!271 = !DILocation(line: 177, column: 40, scope: !222)
!272 = !DILocation(line: 177, column: 49, scope: !222)
!273 = !DILocation(line: 177, column: 32, scope: !222)
!274 = !DILocation(line: 178, column: 9, scope: !275)
!275 = distinct !DILexicalBlock(scope: !222, file: !3, line: 178, column: 9)
!276 = !DILocation(line: 178, column: 14, scope: !275)
!277 = !DILocation(line: 179, column: 38, scope: !278)
!278 = distinct !DILexicalBlock(scope: !275, file: !3, line: 178, column: 23)
!279 = !DILocation(line: 179, column: 44, scope: !278)
!280 = !DILocation(line: 179, column: 9, scope: !278)
!281 = !DILocation(line: 180, column: 5, scope: !278)
!282 = !DILocation(line: 181, column: 55, scope: !222)
!283 = !DILocation(line: 181, column: 64, scope: !222)
!284 = !DILocation(line: 181, column: 43, scope: !222)
!285 = !DILocation(line: 181, column: 5, scope: !222)
!286 = !DILocation(line: 182, column: 48, scope: !222)
!287 = !DILocation(line: 182, column: 57, scope: !222)
!288 = !DILocation(line: 182, column: 37, scope: !222)
!289 = !DILocation(line: 182, column: 5, scope: !222)
!290 = !DILocation(line: 183, column: 1, scope: !222)
!291 = distinct !DISubprogram(name: "table_lookup", scope: !3, file: !3, line: 64, type: !292, scopeLine: 64, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!292 = !DISubroutineType(types: !293)
!293 = !{!6, !180, !74}
!294 = !DILocalVariable(name: "table", arg: 1, scope: !291, file: !3, line: 64, type: !180)
!295 = !DILocation(line: 64, column: 45, scope: !291)
!296 = !DILocalVariable(name: "word", arg: 2, scope: !291, file: !3, line: 64, type: !74)
!297 = !DILocation(line: 64, column: 64, scope: !291)
!298 = !DILocalVariable(name: "index", scope: !291, file: !3, line: 65, type: !12)
!299 = !DILocation(line: 65, column: 18, scope: !291)
!300 = !DILocation(line: 65, column: 36, scope: !291)
!301 = !DILocation(line: 65, column: 26, scope: !291)
!302 = !DILocation(line: 65, column: 42, scope: !291)
!303 = !DILocalVariable(name: "probe", scope: !304, file: !3, line: 66, type: !6)
!304 = distinct !DILexicalBlock(scope: !291, file: !3, line: 66, column: 5)
!305 = !DILocation(line: 66, column: 14, scope: !304)
!306 = !DILocation(line: 66, column: 10, scope: !304)
!307 = !DILocation(line: 66, column: 25, scope: !308)
!308 = distinct !DILexicalBlock(scope: !304, file: !3, line: 66, column: 5)
!309 = !DILocation(line: 66, column: 31, scope: !308)
!310 = !DILocation(line: 66, column: 5, scope: !304)
!311 = !DILocalVariable(name: "slot", scope: !312, file: !3, line: 67, type: !225)
!312 = distinct !DILexicalBlock(scope: !308, file: !3, line: 66, column: 54)
!313 = !DILocation(line: 67, column: 29, scope: !312)
!314 = !DILocation(line: 67, column: 37, scope: !312)
!315 = !DILocation(line: 67, column: 44, scope: !312)
!316 = !DILocation(line: 67, column: 50, scope: !312)
!317 = !DILocation(line: 68, column: 13, scope: !318)
!318 = distinct !DILexicalBlock(scope: !312, file: !3, line: 68, column: 13)
!319 = !DILocation(line: 68, column: 19, scope: !318)
!320 = !DILocation(line: 68, column: 25, scope: !318)
!321 = !DILocation(line: 69, column: 13, scope: !322)
!322 = distinct !DILexicalBlock(scope: !318, file: !3, line: 68, column: 31)
!323 = !DILocation(line: 71, column: 20, scope: !324)
!324 = distinct !DILexicalBlock(scope: !312, file: !3, line: 71, column: 13)
!325 = !DILocation(line: 71, column: 26, scope: !324)
!326 = !DILocation(line: 71, column: 32, scope: !324)
!327 = !DILocation(line: 71, column: 13, scope: !324)
!328 = !DILocation(line: 71, column: 38, scope: !324)
!329 = !DILocation(line: 72, column: 20, scope: !330)
!330 = distinct !DILexicalBlock(scope: !324, file: !3, line: 71, column: 44)
!331 = !DILocation(line: 72, column: 26, scope: !330)
!332 = !DILocation(line: 72, column: 13, scope: !330)
!333 = !DILocation(line: 74, column: 18, scope: !312)
!334 = !DILocation(line: 74, column: 24, scope: !312)
!335 = !DILocation(line: 74, column: 29, scope: !312)
!336 = !DILocation(line: 74, column: 15, scope: !312)
!337 = !DILocation(line: 75, column: 5, scope: !312)
!338 = !DILocation(line: 66, column: 50, scope: !308)
!339 = !DILocation(line: 66, column: 5, scope: !308)
!340 = distinct !{!340, !310, !341, !174}
!341 = !DILocation(line: 75, column: 5, scope: !304)
!342 = !DILocation(line: 76, column: 5, scope: !291)
!343 = !DILocation(line: 77, column: 1, scope: !291)
!344 = distinct !DISubprogram(name: "next_word", scope: !3, file: !3, line: 80, type: !345, scopeLine: 80, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!345 = !DISubroutineType(types: !346)
!346 = !{!6, !347, !348}
!347 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !74, size: 64)
!348 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !29, size: 64)
!349 = !DILocalVariable(name: "text", arg: 1, scope: !344, file: !3, line: 80, type: !347)
!350 = !DILocation(line: 80, column: 35, scope: !344)
!351 = !DILocalVariable(name: "word", arg: 2, scope: !344, file: !3, line: 80, type: !348)
!352 = !DILocation(line: 80, column: 47, scope: !344)
!353 = !DILocalVariable(name: "p", scope: !344, file: !3, line: 81, type: !74)
!354 = !DILocation(line: 81, column: 17, scope: !344)
!355 = !DILocation(line: 81, column: 22, scope: !344)
!356 = !DILocation(line: 81, column: 21, scope: !344)
!357 = !DILocation(line: 82, column: 5, scope: !344)
!358 = !DILocation(line: 82, column: 13, scope: !344)
!359 = !DILocation(line: 82, column: 12, scope: !344)
!360 = !DILocation(line: 82, column: 15, scope: !344)
!361 = !DILocation(line: 82, column: 23, scope: !344)
!362 = !DILocation(line: 82, column: 27, scope: !344)
!363 = !DILocation(line: 82, column: 51, scope: !344)
!364 = !DILocation(line: 82, column: 50, scope: !344)
!365 = !DILocation(line: 82, column: 26, scope: !344)
!366 = !DILocation(line: 0, scope: !344)
!367 = !DILocation(line: 83, column: 10, scope: !368)
!368 = distinct !DILexicalBlock(scope: !344, file: !3, line: 82, column: 55)
!369 = distinct !{!369, !357, !370, !174}
!370 = !DILocation(line: 84, column: 5, scope: !344)
!371 = !DILocalVariable(name: "length", scope: !344, file: !3, line: 85, type: !6)
!372 = !DILocation(line: 85, column: 9, scope: !344)
!373 = !DILocation(line: 86, column: 5, scope: !344)
!374 = !DILocation(line: 86, column: 12, scope: !344)
!375 = !DILocation(line: 86, column: 36, scope: !344)
!376 = !DILocation(line: 86, column: 35, scope: !344)
!377 = !DILocation(line: 87, column: 13, scope: !378)
!378 = distinct !DILexicalBlock(scope: !379, file: !3, line: 87, column: 13)
!379 = distinct !DILexicalBlock(scope: !344, file: !3, line: 86, column: 40)
!380 = !DILocation(line: 87, column: 20, scope: !378)
!381 = !DILocation(line: 88, column: 60, scope: !382)
!382 = distinct !DILexicalBlock(scope: !378, file: !3, line: 87, column: 36)
!383 = !DILocation(line: 88, column: 59, scope: !382)
!384 = !DILocation(line: 88, column: 44, scope: !382)
!385 = !DILocation(line: 88, column: 36, scope: !382)
!386 = !DILocation(line: 88, column: 30, scope: !382)
!387 = !DILocation(line: 88, column: 13, scope: !382)
!388 = !DILocation(line: 88, column: 24, scope: !382)
!389 = !DILocation(line: 88, column: 28, scope: !382)
!390 = !DILocation(line: 89, column: 9, scope: !382)
!391 = !DILocation(line: 90, column: 10, scope: !379)
!392 = distinct !{!392, !373, !393, !174}
!393 = !DILocation(line: 91, column: 5, scope: !344)
!394 = !DILocation(line: 92, column: 5, scope: !344)
!395 = !DILocation(line: 92, column: 10, scope: !344)
!396 = !DILocation(line: 92, column: 18, scope: !344)
!397 = !DILocation(line: 93, column: 13, scope: !344)
!398 = !DILocation(line: 93, column: 6, scope: !344)
!399 = !DILocation(line: 93, column: 11, scope: !344)
!400 = !DILocation(line: 94, column: 12, scope: !344)
!401 = !DILocation(line: 94, column: 5, scope: !344)
!402 = distinct !DISubprogram(name: "table_add", scope: !3, file: !3, line: 44, type: !403, scopeLine: 44, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!403 = !DISubroutineType(types: !404)
!404 = !{!6, !138, !74, !6}
!405 = !DILocalVariable(name: "table", arg: 1, scope: !402, file: !3, line: 44, type: !138)
!406 = !DILocation(line: 44, column: 36, scope: !402)
!407 = !DILocalVariable(name: "word", arg: 2, scope: !402, file: !3, line: 44, type: !74)
!408 = !DILocation(line: 44, column: 55, scope: !402)
!409 = !DILocalVariable(name: "position", arg: 3, scope: !402, file: !3, line: 44, type: !6)
!410 = !DILocation(line: 44, column: 65, scope: !402)
!411 = !DILocalVariable(name: "index", scope: !402, file: !3, line: 45, type: !12)
!412 = !DILocation(line: 45, column: 18, scope: !402)
!413 = !DILocation(line: 45, column: 36, scope: !402)
!414 = !DILocation(line: 45, column: 26, scope: !402)
!415 = !DILocation(line: 45, column: 42, scope: !402)
!416 = !DILocalVariable(name: "probe", scope: !417, file: !3, line: 46, type: !6)
!417 = distinct !DILexicalBlock(scope: !402, file: !3, line: 46, column: 5)
!418 = !DILocation(line: 46, column: 14, scope: !417)
!419 = !DILocation(line: 46, column: 10, scope: !417)
!420 = !DILocation(line: 46, column: 25, scope: !421)
!421 = distinct !DILexicalBlock(scope: !417, file: !3, line: 46, column: 5)
!422 = !DILocation(line: 46, column: 31, scope: !421)
!423 = !DILocation(line: 46, column: 5, scope: !417)
!424 = !DILocalVariable(name: "slot", scope: !425, file: !3, line: 47, type: !182)
!425 = distinct !DILexicalBlock(scope: !421, file: !3, line: 46, column: 54)
!426 = !DILocation(line: 47, column: 23, scope: !425)
!427 = !DILocation(line: 47, column: 31, scope: !425)
!428 = !DILocation(line: 47, column: 38, scope: !425)
!429 = !DILocation(line: 47, column: 44, scope: !425)
!430 = !DILocation(line: 48, column: 13, scope: !431)
!431 = distinct !DILexicalBlock(scope: !425, file: !3, line: 48, column: 13)
!432 = !DILocation(line: 48, column: 19, scope: !431)
!433 = !DILocation(line: 48, column: 25, scope: !431)
!434 = !DILocation(line: 49, column: 21, scope: !435)
!435 = distinct !DILexicalBlock(scope: !431, file: !3, line: 48, column: 31)
!436 = !DILocation(line: 49, column: 27, scope: !435)
!437 = !DILocation(line: 49, column: 33, scope: !435)
!438 = !DILocation(line: 49, column: 13, scope: !435)
!439 = !DILocation(line: 50, column: 13, scope: !435)
!440 = !DILocation(line: 50, column: 19, scope: !435)
!441 = !DILocation(line: 50, column: 25, scope: !435)
!442 = !DILocation(line: 51, column: 32, scope: !435)
!443 = !DILocation(line: 51, column: 13, scope: !435)
!444 = !DILocation(line: 51, column: 19, scope: !435)
!445 = !DILocation(line: 51, column: 30, scope: !435)
!446 = !DILocation(line: 52, column: 13, scope: !435)
!447 = !DILocation(line: 52, column: 20, scope: !435)
!448 = !DILocation(line: 52, column: 24, scope: !435)
!449 = !DILocation(line: 53, column: 13, scope: !435)
!450 = !DILocation(line: 55, column: 20, scope: !451)
!451 = distinct !DILexicalBlock(scope: !425, file: !3, line: 55, column: 13)
!452 = !DILocation(line: 55, column: 26, scope: !451)
!453 = !DILocation(line: 55, column: 32, scope: !451)
!454 = !DILocation(line: 55, column: 13, scope: !451)
!455 = !DILocation(line: 55, column: 38, scope: !451)
!456 = !DILocation(line: 56, column: 13, scope: !457)
!457 = distinct !DILexicalBlock(scope: !451, file: !3, line: 55, column: 44)
!458 = !DILocation(line: 56, column: 19, scope: !457)
!459 = !DILocation(line: 56, column: 24, scope: !457)
!460 = !DILocation(line: 57, column: 13, scope: !457)
!461 = !DILocation(line: 59, column: 18, scope: !425)
!462 = !DILocation(line: 59, column: 24, scope: !425)
!463 = !DILocation(line: 59, column: 29, scope: !425)
!464 = !DILocation(line: 59, column: 15, scope: !425)
!465 = !DILocation(line: 60, column: 5, scope: !425)
!466 = !DILocation(line: 46, column: 50, scope: !421)
!467 = !DILocation(line: 46, column: 5, scope: !421)
!468 = distinct !{!468, !423, !469, !174}
!469 = !DILocation(line: 60, column: 5, scope: !417)
!470 = !DILocation(line: 61, column: 5, scope: !402)
!471 = !DILocation(line: 62, column: 1, scope: !402)
!472 = distinct !DISubprogram(name: "hash_word", scope: !3, file: !3, line: 30, type: !473, scopeLine: 30, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!473 = !DISubroutineType(types: !474)
!474 = !{!12, !74}
!475 = !DILocalVariable(name: "word", arg: 1, scope: !472, file: !3, line: 30, type: !74)
!476 = !DILocation(line: 30, column: 43, scope: !472)
!477 = !DILocalVariable(name: "hash", scope: !472, file: !3, line: 31, type: !12)
!478 = !DILocation(line: 31, column: 18, scope: !472)
!479 = !DILocalVariable(name: "p", scope: !480, file: !3, line: 32, type: !74)
!480 = distinct !DILexicalBlock(scope: !472, file: !3, line: 32, column: 5)
!481 = !DILocation(line: 32, column: 22, scope: !480)
!482 = !DILocation(line: 32, column: 26, scope: !480)
!483 = !DILocation(line: 32, column: 10, scope: !480)
!484 = !DILocation(line: 32, column: 33, scope: !485)
!485 = distinct !DILexicalBlock(scope: !480, file: !3, line: 32, column: 5)
!486 = !DILocation(line: 32, column: 32, scope: !485)
!487 = !DILocation(line: 32, column: 35, scope: !485)
!488 = !DILocation(line: 32, column: 5, scope: !480)
!489 = !DILocation(line: 33, column: 33, scope: !490)
!490 = distinct !DILexicalBlock(scope: !485, file: !3, line: 32, column: 49)
!491 = !DILocation(line: 33, column: 32, scope: !490)
!492 = !DILocation(line: 33, column: 17, scope: !490)
!493 = !DILocation(line: 33, column: 14, scope: !490)
!494 = !DILocation(line: 34, column: 14, scope: !490)
!495 = !DILocation(line: 35, column: 5, scope: !490)
!496 = !DILocation(line: 32, column: 45, scope: !485)
!497 = !DILocation(line: 32, column: 5, scope: !485)
!498 = distinct !{!498, !488, !499, !174}
!499 = !DILocation(line: 35, column: 5, scope: !480)
!500 = !DILocation(line: 36, column: 12, scope: !472)
!501 = !DILocation(line: 36, column: 5, scope: !472)
!502 = distinct !DISubprogram(name: "by_count", scope: !3, file: !3, line: 111, type: !503, scopeLine: 111, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!503 = !DISubroutineType(types: !504)
!504 = !{!6, !505, !505}
!505 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !506, size: 64)
!506 = !DIDerivedType(tag: DW_TAG_const_type, baseType: null)
!507 = !DILocalVariable(name: "a", arg: 1, scope: !502, file: !3, line: 111, type: !505)
!508 = !DILocation(line: 111, column: 33, scope: !502)
!509 = !DILocalVariable(name: "b", arg: 2, scope: !502, file: !3, line: 111, type: !505)
!510 = !DILocation(line: 111, column: 48, scope: !502)
!511 = !DILocalVariable(name: "x", scope: !502, file: !3, line: 112, type: !225)
!512 = !DILocation(line: 112, column: 25, scope: !502)
!513 = !DILocation(line: 112, column: 29, scope: !502)
!514 = !DILocalVariable(name: "y", scope: !502, file: !3, line: 113, type: !225)
!515 = !DILocation(line: 113, column: 25, scope: !502)
!516 = !DILocation(line: 113, column: 29, scope: !502)
!517 = !DILocation(line: 114, column: 9, scope: !518)
!518 = distinct !DILexicalBlock(scope: !502, file: !3, line: 114, column: 9)
!519 = !DILocation(line: 114, column: 12, scope: !518)
!520 = !DILocation(line: 114, column: 21, scope: !518)
!521 = !DILocation(line: 114, column: 24, scope: !518)
!522 = !DILocation(line: 114, column: 18, scope: !518)
!523 = !DILocation(line: 115, column: 16, scope: !524)
!524 = distinct !DILexicalBlock(scope: !518, file: !3, line: 114, column: 31)
!525 = !DILocation(line: 115, column: 19, scope: !524)
!526 = !DILocation(line: 115, column: 27, scope: !524)
!527 = !DILocation(line: 115, column: 30, scope: !524)
!528 = !DILocation(line: 115, column: 25, scope: !524)
!529 = !DILocation(line: 115, column: 9, scope: !524)
!530 = !DILocation(line: 117, column: 12, scope: !502)
!531 = !DILocation(line: 117, column: 15, scope: !502)
!532 = !DILocation(line: 117, column: 28, scope: !502)
!533 = !DILocation(line: 117, column: 31, scope: !502)
!534 = !DILocation(line: 117, column: 26, scope: !502)
!535 = !DILocation(line: 117, column: 5, scope: !502)
!536 = !DILocation(line: 118, column: 1, scope: !502)
!537 = distinct !DISubprogram(name: "print_bar", scope: !3, file: !3, line: 162, type: !538, scopeLine: 162, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!538 = !DISubroutineType(types: !539)
!539 = !{null, !6, !6}
!540 = !DILocalVariable(name: "count", arg: 1, scope: !537, file: !3, line: 162, type: !6)
!541 = !DILocation(line: 162, column: 27, scope: !537)
!542 = !DILocalVariable(name: "widest", arg: 2, scope: !537, file: !3, line: 162, type: !6)
!543 = !DILocation(line: 162, column: 38, scope: !537)
!544 = !DILocalVariable(name: "width", scope: !537, file: !3, line: 163, type: !6)
!545 = !DILocation(line: 163, column: 9, scope: !537)
!546 = !DILocation(line: 163, column: 17, scope: !537)
!547 = !DILocation(line: 163, column: 24, scope: !537)
!548 = !DILocation(line: 163, column: 30, scope: !537)
!549 = !DILocation(line: 163, column: 36, scope: !537)
!550 = !DILocation(line: 163, column: 43, scope: !537)
!551 = !DILocation(line: 163, column: 41, scope: !537)
!552 = !DILocalVariable(name: "i", scope: !553, file: !3, line: 164, type: !6)
!553 = distinct !DILexicalBlock(scope: !537, file: !3, line: 164, column: 5)
!554 = !DILocation(line: 164, column: 14, scope: !553)
!555 = !DILocation(line: 164, column: 10, scope: !553)
!556 = !DILocation(line: 164, column: 21, scope: !557)
!557 = distinct !DILexicalBlock(scope: !553, file: !3, line: 164, column: 5)
!558 = !DILocation(line: 164, column: 25, scope: !557)
!559 = !DILocation(line: 164, column: 23, scope: !557)
!560 = !DILocation(line: 164, column: 5, scope: !553)
!561 = !DILocation(line: 165, column: 9, scope: !562)
!562 = distinct !DILexicalBlock(scope: !557, file: !3, line: 164, column: 37)
!563 = !DILocation(line: 166, column: 5, scope: !562)
!564 = !DILocation(line: 164, column: 33, scope: !557)
!565 = !DILocation(line: 164, column: 5, scope: !557)
!566 = distinct !{!566, !560, !567, !174}
!567 = !DILocation(line: 166, column: 5, scope: !553)
!568 = !DILocation(line: 167, column: 5, scope: !537)
!569 = !DILocation(line: 168, column: 1, scope: !537)
!570 = distinct !DISubprogram(name: "longest", scope: !3, file: !3, line: 141, type: !571, scopeLine: 141, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!571 = !DISubroutineType(types: !572)
!572 = !{!225, !225, !6}
!573 = !DILocalVariable(name: "entries", arg: 1, scope: !570, file: !3, line: 141, type: !225)
!574 = !DILocation(line: 141, column: 56, scope: !570)
!575 = !DILocalVariable(name: "n", arg: 2, scope: !570, file: !3, line: 141, type: !6)
!576 = !DILocation(line: 141, column: 69, scope: !570)
!577 = !DILocalVariable(name: "best", scope: !570, file: !3, line: 142, type: !225)
!578 = !DILocation(line: 142, column: 25, scope: !570)
!579 = !DILocalVariable(name: "best_length", scope: !570, file: !3, line: 143, type: !30)
!580 = !DILocation(line: 143, column: 12, scope: !570)
!581 = !DILocalVariable(name: "i", scope: !582, file: !3, line: 144, type: !6)
!582 = distinct !DILexicalBlock(scope: !570, file: !3, line: 144, column: 5)
!583 = !DILocation(line: 144, column: 14, scope: !582)
!584 = !DILocation(line: 144, column: 10, scope: !582)
!585 = !DILocation(line: 144, column: 21, scope: !586)
!586 = distinct !DILexicalBlock(scope: !582, file: !3, line: 144, column: 5)
!587 = !DILocation(line: 144, column: 25, scope: !586)
!588 = !DILocation(line: 144, column: 23, scope: !586)
!589 = !DILocation(line: 144, column: 5, scope: !582)
!590 = !DILocalVariable(name: "length", scope: !591, file: !3, line: 145, type: !30)
!591 = distinct !DILexicalBlock(scope: !586, file: !3, line: 144, column: 33)
!592 = !DILocation(line: 145, column: 16, scope: !591)
!593 = !DILocation(line: 145, column: 32, scope: !591)
!594 = !DILocation(line: 145, column: 40, scope: !591)
!595 = !DILocation(line: 145, column: 43, scope: !591)
!596 = !DILocation(line: 145, column: 25, scope: !591)
!597 = !DILocation(line: 146, column: 13, scope: !598)
!598 = distinct !DILexicalBlock(scope: !591, file: !3, line: 146, column: 13)
!599 = !DILocation(line: 146, column: 22, scope: !598)
!600 = !DILocation(line: 146, column: 20, scope: !598)
!601 = !DILocation(line: 147, column: 21, scope: !602)
!602 = distinct !DILexicalBlock(scope: !598, file: !3, line: 146, column: 35)
!603 = !DILocation(line: 147, column: 29, scope: !602)
!604 = !DILocation(line: 147, column: 18, scope: !602)
!605 = !DILocation(line: 148, column: 27, scope: !602)
!606 = !DILocation(line: 148, column: 25, scope: !602)
!607 = !DILocation(line: 149, column: 9, scope: !602)
!608 = !DILocation(line: 150, column: 5, scope: !591)
!609 = !DILocation(line: 144, column: 29, scope: !586)
!610 = !DILocation(line: 144, column: 5, scope: !586)
!611 = distinct !{!611, !589, !612, !174}
!612 = !DILocation(line: 150, column: 5, scope: !582)
!613 = !DILocation(line: 151, column: 12, scope: !570)
!614 = !DILocation(line: 151, column: 5, scope: !570)
!615 = distinct !DISubprogram(name: "mean_length", scope: !3, file: !3, line: 131, type: !616, scopeLine: 131, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!616 = !DISubroutineType(types: !617)
!617 = !{!35, !225, !6}
!618 = !DILocalVariable(name: "entries", arg: 1, scope: !615, file: !3, line: 131, type: !225)
!619 = !DILocation(line: 131, column: 47, scope: !615)
!620 = !DILocalVariable(name: "n", arg: 2, scope: !615, file: !3, line: 131, type: !6)
!621 = !DILocation(line: 131, column: 60, scope: !615)
!622 = !DILocalVariable(name: "letters", scope: !615, file: !3, line: 132, type: !34)
!623 = !DILocation(line: 132, column: 10, scope: !615)
!624 = !DILocalVariable(name: "words", scope: !615, file: !3, line: 133, type: !34)
!625 = !DILocation(line: 133, column: 10, scope: !615)
!626 = !DILocalVariable(name: "i", scope: !627, file: !3, line: 134, type: !6)
!627 = distinct !DILexicalBlock(scope: !615, file: !3, line: 134, column: 5)
!628 = !DILocation(line: 134, column: 14, scope: !627)
!629 = !DILocation(line: 134, column: 10, scope: !627)
!630 = !DILocation(line: 134, column: 21, scope: !631)
!631 = distinct !DILexicalBlock(scope: !627, file: !3, line: 134, column: 5)
!632 = !DILocation(line: 134, column: 25, scope: !631)
!633 = !DILocation(line: 134, column: 23, scope: !631)
!634 = !DILocation(line: 134, column: 5, scope: !627)
!635 = !DILocation(line: 135, column: 33, scope: !636)
!636 = distinct !DILexicalBlock(scope: !631, file: !3, line: 134, column: 33)
!637 = !DILocation(line: 135, column: 41, scope: !636)
!638 = !DILocation(line: 135, column: 44, scope: !636)
!639 = !DILocation(line: 135, column: 26, scope: !636)
!640 = !DILocation(line: 135, column: 52, scope: !636)
!641 = !DILocation(line: 135, column: 60, scope: !636)
!642 = !DILocation(line: 135, column: 63, scope: !636)
!643 = !DILocation(line: 135, column: 50, scope: !636)
!644 = !DILocation(line: 135, column: 17, scope: !636)
!645 = !DILocation(line: 136, column: 18, scope: !636)
!646 = !DILocation(line: 136, column: 26, scope: !636)
!647 = !DILocation(line: 136, column: 29, scope: !636)
!648 = !DILocation(line: 136, column: 15, scope: !636)
!649 = !DILocation(line: 137, column: 5, scope: !636)
!650 = !DILocation(line: 134, column: 29, scope: !631)
!651 = !DILocation(line: 134, column: 5, scope: !631)
!652 = distinct !{!652, !634, !653, !174}
!653 = !DILocation(line: 137, column: 5, scope: !627)
!654 = !DILocation(line: 138, column: 12, scope: !615)
!655 = !DILocation(line: 138, column: 18, scope: !615)
!656 = !DILocation(line: 138, column: 32, scope: !615)
!657 = !DILocation(line: 138, column: 24, scope: !615)
!658 = !DILocation(line: 138, column: 50, scope: !615)
!659 = !DILocation(line: 138, column: 42, scope: !615)
!660 = !DILocation(line: 138, column: 40, scope: !615)
!661 = !DILocation(line: 138, column: 5, scope: !615)
!662 = distinct !DISubprogram(name: "singletons", scope: !3, file: !3, line: 154, type: !663, scopeLine: 154, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!663 = !DISubroutineType(types: !664)
!664 = !{!6, !225, !6}
!665 = !DILocalVariable(name: "entries", arg: 1, scope: !662, file: !3, line: 154, type: !225)
!666 = !DILocation(line: 154, column: 43, scope: !662)
!667 = !DILocalVariable(name: "n", arg: 2, scope: !662, file: !3, line: 154, type: !6)
!668 = !DILocation(line: 154, column: 56, scope: !662)
!669 = !DILocalVariable(name: "count", scope: !662, file: !3, line: 155, type: !6)
!670 = !DILocation(line: 155, column: 9, scope: !662)
!671 = !DILocalVariable(name: "i", scope: !672, file: !3, line: 156, type: !6)
!672 = distinct !DILexicalBlock(scope: !662, file: !3, line: 156, column: 5)
!673 = !DILocation(line: 156, column: 14, scope: !672)
!674 = !DILocation(line: 156, column: 18, scope: !672)
!675 = !DILocation(line: 156, column: 20, scope: !672)
!676 = !DILocation(line: 156, column: 10, scope: !672)
!677 = !DILocation(line: 156, column: 25, scope: !678)
!678 = distinct !DILexicalBlock(scope: !672, file: !3, line: 156, column: 5)
!679 = !DILocation(line: 156, column: 27, scope: !678)
!680 = !DILocation(line: 156, column: 32, scope: !678)
!681 = !DILocation(line: 156, column: 35, scope: !678)
!682 = !DILocation(line: 156, column: 43, scope: !678)
!683 = !DILocation(line: 156, column: 46, scope: !678)
!684 = !DILocation(line: 156, column: 52, scope: !678)
!685 = !DILocation(line: 0, scope: !678)
!686 = !DILocation(line: 156, column: 5, scope: !672)
!687 = !DILocation(line: 157, column: 14, scope: !688)
!688 = distinct !DILexicalBlock(scope: !678, file: !3, line: 156, column: 63)
!689 = !DILocation(line: 158, column: 5, scope: !688)
!690 = !DILocation(line: 156, column: 59, scope: !678)
!691 = !DILocation(line: 156, column: 5, scope: !678)
!692 = distinct !{!692, !686, !693, !174}
!693 = !DILocation(line: 158, column: 5, scope: !672)
!694 = !DILocation(line: 159, column: 12, scope: !662)
!695 = !DILocation(line: 159, column: 5, scope: !662)
