; ModuleID = '/workspace/out/word_frequency_O0.bc'
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
  call void @table_init(ptr noundef @main.table), !dbg !108
  %0 = load ptr, ptr @passage, align 8, !dbg !109
  %call = call i32 @count_words(ptr noundef @main.table, ptr noundef %0), !dbg !110
    #dbg_value(i32 %call, !111, !DIExpression(), !112)
  %call1 = call i32 @collect(ptr noundef @main.table, ptr noundef @main.entries), !dbg !113
    #dbg_value(i32 %call1, !114, !DIExpression(), !112)
  call void @report(ptr noundef @main.entries, i32 noundef %call1, i32 noundef %call), !dbg !115
  %call2 = call i32 @table_lookup(ptr noundef @main.table, ptr noundef @.str), !dbg !116
    #dbg_value(i32 %call2, !117, !DIExpression(), !112)
  %call3 = call i32 @table_lookup(ptr noundef @main.table, ptr noundef @.str.1), !dbg !118
    #dbg_value(i32 %call3, !119, !DIExpression(), !112)
  %call4 = call i32 (ptr, ...) @printf(ptr noundef @.str.2, i32 noundef %call2, i32 noundef %call3), !dbg !120
  %cmp = icmp sgt i32 %call2, 0, !dbg !121
  br i1 %cmp, label %land.rhs, label %land.end, !dbg !122

land.rhs:                                         ; preds = %entry
  %cmp5 = icmp eq i32 %call3, 0, !dbg !123
  br label %land.end

land.end:                                         ; preds = %land.rhs, %entry
  %1 = phi i1 [ false, %entry ], [ %cmp5, %land.rhs ], !dbg !112
  %2 = zext i1 %1 to i64, !dbg !124
  %cond = select i1 %1, i32 0, i32 1, !dbg !124
  ret i32 %cond, !dbg !125
}

; Function Attrs: noinline nounwind uwtable
define internal void @table_init(ptr noundef %table) #0 !dbg !126 {
entry:
    #dbg_value(ptr %table, !130, !DIExpression(), !131)
  call void @llvm.memset.p0.i64(ptr align 4 %table, i8 0, i64 8196, i1 false), !dbg !132
  ret void, !dbg !133
}

; Function Attrs: noinline nounwind uwtable
define internal i32 @count_words(ptr noundef %table, ptr noundef %text) #0 !dbg !134 {
entry:
  %text.addr = alloca ptr, align 8
  %word = alloca [24 x i8], align 16
    #dbg_value(ptr %table, !137, !DIExpression(), !138)
  store ptr %text, ptr %text.addr, align 8
    #dbg_declare(ptr %text.addr, !139, !DIExpression(), !140)
    #dbg_declare(ptr %word, !141, !DIExpression(), !142)
    #dbg_value(i32 0, !143, !DIExpression(), !138)
  br label %while.cond, !dbg !144

while.cond:                                       ; preds = %if.end, %entry
  %position.0 = phi i32 [ 0, %entry ], [ %inc, %if.end ], !dbg !138
    #dbg_value(i32 %position.0, !143, !DIExpression(), !138)
  %arraydecay = getelementptr inbounds [24 x i8], ptr %word, i64 0, i64 0, !dbg !145
  %call = call i32 @next_word(ptr noundef %text.addr, ptr noundef %arraydecay), !dbg !146
  %cmp = icmp sgt i32 %call, 0, !dbg !147
  br i1 %cmp, label %while.body, label %while.end, !dbg !144

while.body:                                       ; preds = %while.cond
  %arraydecay1 = getelementptr inbounds [24 x i8], ptr %word, i64 0, i64 0, !dbg !148
  %call2 = call i32 @table_add(ptr noundef %table, ptr noundef %arraydecay1, i32 noundef %position.0), !dbg !151
  %cmp3 = icmp slt i32 %call2, 0, !dbg !152
  br i1 %cmp3, label %if.then, label %if.end, !dbg !152

if.then:                                          ; preds = %while.body
  %0 = load ptr, ptr @stderr, align 8, !dbg !153
  %call4 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %0, ptr noundef @.str.3, i32 noundef %position.0) #7, !dbg !155
  br label %while.end, !dbg !156

if.end:                                           ; preds = %while.body
  %inc = add nsw i32 %position.0, 1, !dbg !157
    #dbg_value(i32 %inc, !143, !DIExpression(), !138)
  br label %while.cond, !dbg !144, !llvm.loop !158

while.end:                                        ; preds = %if.then, %while.cond
  ret i32 %position.0, !dbg !161
}

; Function Attrs: noinline nounwind uwtable
define internal i32 @collect(ptr noundef %table, ptr noundef %out) #0 !dbg !162 {
entry:
    #dbg_value(ptr %table, !168, !DIExpression(), !169)
    #dbg_value(ptr %out, !170, !DIExpression(), !169)
    #dbg_value(i32 0, !171, !DIExpression(), !169)
    #dbg_value(i32 0, !172, !DIExpression(), !174)
  br label %for.cond, !dbg !175

for.cond:                                         ; preds = %for.inc, %entry
  %n.0 = phi i32 [ 0, %entry ], [ %n.1, %for.inc ], !dbg !169
  %i.0 = phi i32 [ 0, %entry ], [ %inc7, %for.inc ], !dbg !176
    #dbg_value(i32 %i.0, !172, !DIExpression(), !174)
    #dbg_value(i32 %n.0, !171, !DIExpression(), !169)
  %cmp = icmp slt i32 %i.0, 256, !dbg !177
  br i1 %cmp, label %for.body, label %for.end, !dbg !179

for.body:                                         ; preds = %for.cond
  %slots = getelementptr inbounds nuw %struct.table, ptr %table, i32 0, i32 0, !dbg !180
  %idxprom = sext i32 %i.0 to i64, !dbg !183
  %arrayidx = getelementptr inbounds [256 x %struct.entry], ptr %slots, i64 0, i64 %idxprom, !dbg !183
  %count = getelementptr inbounds nuw %struct.entry, ptr %arrayidx, i32 0, i32 1, !dbg !184
  %0 = load i32, ptr %count, align 4, !dbg !184
  %cmp1 = icmp sgt i32 %0, 0, !dbg !185
  br i1 %cmp1, label %if.then, label %if.end, !dbg !185

if.then:                                          ; preds = %for.body
  %inc = add nsw i32 %n.0, 1, !dbg !186
    #dbg_value(i32 %inc, !171, !DIExpression(), !169)
  %idxprom2 = sext i32 %n.0 to i64, !dbg !188
  %arrayidx3 = getelementptr inbounds %struct.entry, ptr %out, i64 %idxprom2, !dbg !188
  %slots4 = getelementptr inbounds nuw %struct.table, ptr %table, i32 0, i32 0, !dbg !189
  %idxprom5 = sext i32 %i.0 to i64, !dbg !190
  %arrayidx6 = getelementptr inbounds [256 x %struct.entry], ptr %slots4, i64 0, i64 %idxprom5, !dbg !190
  call void @llvm.memcpy.p0.p0.i64(ptr align 4 %arrayidx3, ptr align 4 %arrayidx6, i64 32, i1 false), !dbg !190
  br label %if.end, !dbg !191

if.end:                                           ; preds = %if.then, %for.body
  %n.1 = phi i32 [ %inc, %if.then ], [ %n.0, %for.body ], !dbg !169
    #dbg_value(i32 %n.1, !171, !DIExpression(), !169)
  br label %for.inc, !dbg !192

for.inc:                                          ; preds = %if.end
  %inc7 = add nsw i32 %i.0, 1, !dbg !193
    #dbg_value(i32 %inc7, !172, !DIExpression(), !174)
  br label %for.cond, !dbg !194, !llvm.loop !195

for.end:                                          ; preds = %for.cond
  %conv = sext i32 %n.0 to i64, !dbg !197
  call void @qsort(ptr noundef %out, i64 noundef %conv, i64 noundef 32, ptr noundef @by_count), !dbg !198
  ret i32 %n.0, !dbg !199
}

; Function Attrs: noinline nounwind uwtable
define internal void @report(ptr noundef %entries, i32 noundef %n, i32 noundef %total) #0 !dbg !200 {
entry:
    #dbg_value(ptr %entries, !205, !DIExpression(), !206)
    #dbg_value(i32 %n, !207, !DIExpression(), !206)
    #dbg_value(i32 %total, !208, !DIExpression(), !206)
  %cmp = icmp slt i32 %n, 8, !dbg !209
  br i1 %cmp, label %cond.true, label %cond.false, !dbg !210

cond.true:                                        ; preds = %entry
  br label %cond.end, !dbg !210

cond.false:                                       ; preds = %entry
  br label %cond.end, !dbg !210

cond.end:                                         ; preds = %cond.false, %cond.true
  %cond = phi i32 [ %n, %cond.true ], [ 8, %cond.false ], !dbg !210
    #dbg_value(i32 %cond, !211, !DIExpression(), !206)
  %call = call i32 (ptr, ...) @printf(ptr noundef @.str.5, i32 noundef %total, i32 noundef %n), !dbg !212
    #dbg_value(i32 0, !213, !DIExpression(), !215)
  br label %for.cond, !dbg !216

for.cond:                                         ; preds = %for.inc, %cond.end
  %i.0 = phi i32 [ 0, %cond.end ], [ %inc, %for.inc ], !dbg !217
    #dbg_value(i32 %i.0, !213, !DIExpression(), !215)
  %cmp1 = icmp slt i32 %i.0, %cond, !dbg !218
  br i1 %cmp1, label %for.body, label %for.end, !dbg !220

for.body:                                         ; preds = %for.cond
  %idxprom = sext i32 %i.0 to i64, !dbg !221
  %arrayidx = getelementptr inbounds %struct.entry, ptr %entries, i64 %idxprom, !dbg !221
  %word = getelementptr inbounds nuw %struct.entry, ptr %arrayidx, i32 0, i32 0, !dbg !223
  %arraydecay = getelementptr inbounds [24 x i8], ptr %word, i64 0, i64 0, !dbg !221
  %idxprom2 = sext i32 %i.0 to i64, !dbg !224
  %arrayidx3 = getelementptr inbounds %struct.entry, ptr %entries, i64 %idxprom2, !dbg !224
  %count = getelementptr inbounds nuw %struct.entry, ptr %arrayidx3, i32 0, i32 1, !dbg !225
  %0 = load i32, ptr %count, align 4, !dbg !225
  %call4 = call i32 (ptr, ...) @printf(ptr noundef @.str.6, ptr noundef %arraydecay, i32 noundef %0), !dbg !226
  %idxprom5 = sext i32 %i.0 to i64, !dbg !227
  %arrayidx6 = getelementptr inbounds %struct.entry, ptr %entries, i64 %idxprom5, !dbg !227
  %count7 = getelementptr inbounds nuw %struct.entry, ptr %arrayidx6, i32 0, i32 1, !dbg !228
  %1 = load i32, ptr %count7, align 4, !dbg !228
  %arrayidx8 = getelementptr inbounds %struct.entry, ptr %entries, i64 0, !dbg !229
  %count9 = getelementptr inbounds nuw %struct.entry, ptr %arrayidx8, i32 0, i32 1, !dbg !230
  %2 = load i32, ptr %count9, align 4, !dbg !230
  call void @print_bar(i32 noundef %1, i32 noundef %2), !dbg !231
  br label %for.inc, !dbg !232

for.inc:                                          ; preds = %for.body
  %inc = add nsw i32 %i.0, 1, !dbg !233
    #dbg_value(i32 %inc, !213, !DIExpression(), !215)
  br label %for.cond, !dbg !234, !llvm.loop !235

for.end:                                          ; preds = %for.cond
  %call11 = call ptr @longest(ptr noundef %entries, i32 noundef %n), !dbg !237
    #dbg_value(ptr %call11, !238, !DIExpression(), !206)
  %cmp12 = icmp ne ptr %call11, null, !dbg !239
  br i1 %cmp12, label %if.then, label %if.end, !dbg !239

if.then:                                          ; preds = %for.end
  %word13 = getelementptr inbounds nuw %struct.entry, ptr %call11, i32 0, i32 0, !dbg !241
  %arraydecay14 = getelementptr inbounds [24 x i8], ptr %word13, i64 0, i64 0, !dbg !243
  %call15 = call i32 (ptr, ...) @printf(ptr noundef @.str.7, ptr noundef %arraydecay14), !dbg !244
  br label %if.end, !dbg !245

if.end:                                           ; preds = %if.then, %for.end
  %call16 = call double @mean_length(ptr noundef %entries, i32 noundef %n), !dbg !246
  %call17 = call i32 (ptr, ...) @printf(ptr noundef @.str.8, double noundef %call16), !dbg !247
  %call18 = call i32 @singletons(ptr noundef %entries, i32 noundef %n), !dbg !248
  %call19 = call i32 (ptr, ...) @printf(ptr noundef @.str.9, i32 noundef %call18), !dbg !249
  ret void, !dbg !250
}

; Function Attrs: noinline nounwind uwtable
define internal i32 @table_lookup(ptr noundef %table, ptr noundef %word) #0 !dbg !251 {
entry:
    #dbg_value(ptr %table, !254, !DIExpression(), !255)
    #dbg_value(ptr %word, !256, !DIExpression(), !255)
  %call = call i32 @hash_word(ptr noundef %word), !dbg !257
  %rem = urem i32 %call, 256, !dbg !258
    #dbg_value(i32 %rem, !259, !DIExpression(), !255)
    #dbg_value(i32 0, !260, !DIExpression(), !262)
  br label %for.cond, !dbg !263

for.cond:                                         ; preds = %for.inc, %entry
  %index.0 = phi i32 [ %rem, %entry ], [ %rem8, %for.inc ], !dbg !255
  %probe.0 = phi i32 [ 0, %entry ], [ %inc, %for.inc ], !dbg !264
    #dbg_value(i32 %probe.0, !260, !DIExpression(), !262)
    #dbg_value(i32 %index.0, !259, !DIExpression(), !255)
  %cmp = icmp slt i32 %probe.0, 256, !dbg !265
  br i1 %cmp, label %for.body, label %for.end, !dbg !267

for.body:                                         ; preds = %for.cond
  %slots = getelementptr inbounds nuw %struct.table, ptr %table, i32 0, i32 0, !dbg !268
  %idxprom = zext i32 %index.0 to i64, !dbg !270
  %arrayidx = getelementptr inbounds nuw [256 x %struct.entry], ptr %slots, i64 0, i64 %idxprom, !dbg !270
    #dbg_value(ptr %arrayidx, !271, !DIExpression(), !272)
  %count = getelementptr inbounds nuw %struct.entry, ptr %arrayidx, i32 0, i32 1, !dbg !273
  %0 = load i32, ptr %count, align 4, !dbg !273
  %cmp1 = icmp eq i32 %0, 0, !dbg !275
  br i1 %cmp1, label %if.then, label %if.end, !dbg !275

if.then:                                          ; preds = %for.body
  br label %return, !dbg !276

if.end:                                           ; preds = %for.body
  %word2 = getelementptr inbounds nuw %struct.entry, ptr %arrayidx, i32 0, i32 0, !dbg !278
  %arraydecay = getelementptr inbounds [24 x i8], ptr %word2, i64 0, i64 0, !dbg !280
  %call3 = call i32 @strcmp(ptr noundef %arraydecay, ptr noundef %word) #8, !dbg !281
  %cmp4 = icmp eq i32 %call3, 0, !dbg !282
  br i1 %cmp4, label %if.then5, label %if.end7, !dbg !282

if.then5:                                         ; preds = %if.end
  %count6 = getelementptr inbounds nuw %struct.entry, ptr %arrayidx, i32 0, i32 1, !dbg !283
  %1 = load i32, ptr %count6, align 4, !dbg !283
  br label %return, !dbg !285

if.end7:                                          ; preds = %if.end
  %add = add i32 %index.0, 1, !dbg !286
  %rem8 = urem i32 %add, 256, !dbg !287
    #dbg_value(i32 %rem8, !259, !DIExpression(), !255)
  br label %for.inc, !dbg !288

for.inc:                                          ; preds = %if.end7
  %inc = add nsw i32 %probe.0, 1, !dbg !289
    #dbg_value(i32 %inc, !260, !DIExpression(), !262)
  br label %for.cond, !dbg !290, !llvm.loop !291

for.end:                                          ; preds = %for.cond
  br label %return, !dbg !293

return:                                           ; preds = %for.end, %if.then5, %if.then
  %retval.0 = phi i32 [ 0, %if.then ], [ %1, %if.then5 ], [ 0, %for.end ], !dbg !255
  ret i32 %retval.0, !dbg !294
}

declare i32 @printf(ptr noundef, ...) #1

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr writeonly captures(none), i8, i64, i1 immarg) #2

; Function Attrs: noinline nounwind uwtable
define internal i32 @next_word(ptr noundef %text, ptr noundef %word) #0 !dbg !295 {
entry:
    #dbg_value(ptr %text, !300, !DIExpression(), !301)
    #dbg_value(ptr %word, !302, !DIExpression(), !301)
  %0 = load ptr, ptr %text, align 8, !dbg !303
    #dbg_value(ptr %0, !304, !DIExpression(), !301)
  br label %while.cond, !dbg !305

while.cond:                                       ; preds = %while.body, %entry
  %p.0 = phi ptr [ %0, %entry ], [ %incdec.ptr, %while.body ], !dbg !301
    #dbg_value(ptr %p.0, !304, !DIExpression(), !301)
  %1 = load i8, ptr %p.0, align 1, !dbg !306
  %conv = sext i8 %1 to i32, !dbg !306
  %cmp = icmp ne i32 %conv, 0, !dbg !307
  br i1 %cmp, label %land.rhs, label %land.end, !dbg !308

land.rhs:                                         ; preds = %while.cond
  %call = call ptr @__ctype_b_loc() #9, !dbg !309
  %2 = load ptr, ptr %call, align 8, !dbg !309
  %3 = load i8, ptr %p.0, align 1, !dbg !310
  %conv2 = zext i8 %3 to i32, !dbg !309
  %idxprom = sext i32 %conv2 to i64, !dbg !309
  %arrayidx = getelementptr inbounds i16, ptr %2, i64 %idxprom, !dbg !309
  %4 = load i16, ptr %arrayidx, align 2, !dbg !309
  %conv3 = zext i16 %4 to i32, !dbg !309
  %and = and i32 %conv3, 1024, !dbg !309
  %tobool = icmp ne i32 %and, 0, !dbg !311
  %lnot = xor i1 %tobool, true, !dbg !311
  br label %land.end

land.end:                                         ; preds = %land.rhs, %while.cond
  %5 = phi i1 [ false, %while.cond ], [ %lnot, %land.rhs ], !dbg !301
  br i1 %5, label %while.body, label %while.end, !dbg !305

while.body:                                       ; preds = %land.end
  %incdec.ptr = getelementptr inbounds nuw i8, ptr %p.0, i32 1, !dbg !312
    #dbg_value(ptr %incdec.ptr, !304, !DIExpression(), !301)
  br label %while.cond, !dbg !305, !llvm.loop !314

while.end:                                        ; preds = %land.end
    #dbg_value(i32 0, !316, !DIExpression(), !301)
  br label %while.cond4, !dbg !317

while.cond4:                                      ; preds = %if.end, %while.end
  %p.1 = phi ptr [ %p.0, %while.end ], [ %incdec.ptr20, %if.end ], !dbg !301
  %length.0 = phi i32 [ 0, %while.end ], [ %length.1, %if.end ], !dbg !301
    #dbg_value(i32 %length.0, !316, !DIExpression(), !301)
    #dbg_value(ptr %p.1, !304, !DIExpression(), !301)
  %call5 = call ptr @__ctype_b_loc() #9, !dbg !318
  %6 = load ptr, ptr %call5, align 8, !dbg !318
  %7 = load i8, ptr %p.1, align 1, !dbg !319
  %conv6 = zext i8 %7 to i32, !dbg !318
  %idxprom7 = sext i32 %conv6 to i64, !dbg !318
  %arrayidx8 = getelementptr inbounds i16, ptr %6, i64 %idxprom7, !dbg !318
  %8 = load i16, ptr %arrayidx8, align 2, !dbg !318
  %conv9 = zext i16 %8 to i32, !dbg !318
  %and10 = and i32 %conv9, 1024, !dbg !318
  %tobool11 = icmp ne i32 %and10, 0, !dbg !317
  br i1 %tobool11, label %while.body12, label %while.end21, !dbg !317

while.body12:                                     ; preds = %while.cond4
  %cmp13 = icmp slt i32 %length.0, 23, !dbg !320
  br i1 %cmp13, label %if.then, label %if.end, !dbg !320

if.then:                                          ; preds = %while.body12
  %9 = load i8, ptr %p.1, align 1, !dbg !323
  %conv15 = zext i8 %9 to i32, !dbg !325
  %call16 = call i32 @tolower(i32 noundef %conv15) #8, !dbg !326
  %conv17 = trunc i32 %call16 to i8, !dbg !327
  %inc = add nsw i32 %length.0, 1, !dbg !328
    #dbg_value(i32 %inc, !316, !DIExpression(), !301)
  %idxprom18 = sext i32 %length.0 to i64, !dbg !329
  %arrayidx19 = getelementptr inbounds i8, ptr %word, i64 %idxprom18, !dbg !329
  store i8 %conv17, ptr %arrayidx19, align 1, !dbg !330
  br label %if.end, !dbg !331

if.end:                                           ; preds = %if.then, %while.body12
  %length.1 = phi i32 [ %inc, %if.then ], [ %length.0, %while.body12 ], !dbg !301
    #dbg_value(i32 %length.1, !316, !DIExpression(), !301)
  %incdec.ptr20 = getelementptr inbounds nuw i8, ptr %p.1, i32 1, !dbg !332
    #dbg_value(ptr %incdec.ptr20, !304, !DIExpression(), !301)
  br label %while.cond4, !dbg !317, !llvm.loop !333

while.end21:                                      ; preds = %while.cond4
  %idxprom22 = sext i32 %length.0 to i64, !dbg !335
  %arrayidx23 = getelementptr inbounds i8, ptr %word, i64 %idxprom22, !dbg !335
  store i8 0, ptr %arrayidx23, align 1, !dbg !336
  store ptr %p.1, ptr %text, align 8, !dbg !337
  ret i32 %length.0, !dbg !338
}

; Function Attrs: noinline nounwind uwtable
define internal i32 @table_add(ptr noundef %table, ptr noundef %word, i32 noundef %position) #0 !dbg !339 {
entry:
    #dbg_value(ptr %table, !342, !DIExpression(), !343)
    #dbg_value(ptr %word, !344, !DIExpression(), !343)
    #dbg_value(i32 %position, !345, !DIExpression(), !343)
  %call = call i32 @hash_word(ptr noundef %word), !dbg !346
  %rem = urem i32 %call, 256, !dbg !347
    #dbg_value(i32 %rem, !348, !DIExpression(), !343)
    #dbg_value(i32 0, !349, !DIExpression(), !351)
  br label %for.cond, !dbg !352

for.cond:                                         ; preds = %for.inc, %entry
  %index.0 = phi i32 [ %rem, %entry ], [ %rem13, %for.inc ], !dbg !343
  %probe.0 = phi i32 [ 0, %entry ], [ %inc14, %for.inc ], !dbg !353
    #dbg_value(i32 %probe.0, !349, !DIExpression(), !351)
    #dbg_value(i32 %index.0, !348, !DIExpression(), !343)
  %cmp = icmp slt i32 %probe.0, 256, !dbg !354
  br i1 %cmp, label %for.body, label %for.end, !dbg !356

for.body:                                         ; preds = %for.cond
  %slots = getelementptr inbounds nuw %struct.table, ptr %table, i32 0, i32 0, !dbg !357
  %idxprom = zext i32 %index.0 to i64, !dbg !359
  %arrayidx = getelementptr inbounds nuw [256 x %struct.entry], ptr %slots, i64 0, i64 %idxprom, !dbg !359
    #dbg_value(ptr %arrayidx, !360, !DIExpression(), !361)
  %count = getelementptr inbounds nuw %struct.entry, ptr %arrayidx, i32 0, i32 1, !dbg !362
  %0 = load i32, ptr %count, align 4, !dbg !362
  %cmp1 = icmp eq i32 %0, 0, !dbg !364
  br i1 %cmp1, label %if.then, label %if.end, !dbg !364

if.then:                                          ; preds = %for.body
  %word2 = getelementptr inbounds nuw %struct.entry, ptr %arrayidx, i32 0, i32 0, !dbg !365
  %arraydecay = getelementptr inbounds [24 x i8], ptr %word2, i64 0, i64 0, !dbg !367
  %call3 = call ptr @strncpy(ptr noundef %arraydecay, ptr noundef %word, i64 noundef 23) #7, !dbg !368
  %count4 = getelementptr inbounds nuw %struct.entry, ptr %arrayidx, i32 0, i32 1, !dbg !369
  store i32 1, ptr %count4, align 4, !dbg !370
  %first_seen = getelementptr inbounds nuw %struct.entry, ptr %arrayidx, i32 0, i32 2, !dbg !371
  store i32 %position, ptr %first_seen, align 4, !dbg !372
  %used = getelementptr inbounds nuw %struct.table, ptr %table, i32 0, i32 1, !dbg !373
  %1 = load i32, ptr %used, align 4, !dbg !374
  %inc = add nsw i32 %1, 1, !dbg !374
  store i32 %inc, ptr %used, align 4, !dbg !374
  br label %return, !dbg !375

if.end:                                           ; preds = %for.body
  %word5 = getelementptr inbounds nuw %struct.entry, ptr %arrayidx, i32 0, i32 0, !dbg !376
  %arraydecay6 = getelementptr inbounds [24 x i8], ptr %word5, i64 0, i64 0, !dbg !378
  %call7 = call i32 @strcmp(ptr noundef %arraydecay6, ptr noundef %word) #8, !dbg !379
  %cmp8 = icmp eq i32 %call7, 0, !dbg !380
  br i1 %cmp8, label %if.then9, label %if.end12, !dbg !380

if.then9:                                         ; preds = %if.end
  %count10 = getelementptr inbounds nuw %struct.entry, ptr %arrayidx, i32 0, i32 1, !dbg !381
  %2 = load i32, ptr %count10, align 4, !dbg !383
  %inc11 = add nsw i32 %2, 1, !dbg !383
  store i32 %inc11, ptr %count10, align 4, !dbg !383
  br label %return, !dbg !384

if.end12:                                         ; preds = %if.end
  %add = add i32 %index.0, 1, !dbg !385
  %rem13 = urem i32 %add, 256, !dbg !386
    #dbg_value(i32 %rem13, !348, !DIExpression(), !343)
  br label %for.inc, !dbg !387

for.inc:                                          ; preds = %if.end12
  %inc14 = add nsw i32 %probe.0, 1, !dbg !388
    #dbg_value(i32 %inc14, !349, !DIExpression(), !351)
  br label %for.cond, !dbg !389, !llvm.loop !390

for.end:                                          ; preds = %for.cond
  br label %return, !dbg !392

return:                                           ; preds = %for.end, %if.then9, %if.then
  %retval.0 = phi i32 [ 1, %if.then ], [ 0, %if.then9 ], [ -1, %for.end ], !dbg !343
  ret i32 %retval.0, !dbg !393
}

; Function Attrs: nounwind
declare i32 @fprintf(ptr noundef, ptr noundef, ...) #3

; Function Attrs: nounwind willreturn memory(none)
declare ptr @__ctype_b_loc() #4

; Function Attrs: nounwind willreturn memory(read)
declare i32 @tolower(i32 noundef) #5

; Function Attrs: noinline nounwind uwtable
define internal i32 @hash_word(ptr noundef %word) #0 !dbg !394 {
entry:
    #dbg_value(ptr %word, !397, !DIExpression(), !398)
    #dbg_value(i32 -2128831035, !399, !DIExpression(), !398)
    #dbg_value(ptr %word, !400, !DIExpression(), !402)
  br label %for.cond, !dbg !403

for.cond:                                         ; preds = %for.inc, %entry
  %hash.0 = phi i32 [ -2128831035, %entry ], [ %mul, %for.inc ], !dbg !398
  %p.0 = phi ptr [ %word, %entry ], [ %incdec.ptr, %for.inc ], !dbg !404
    #dbg_value(ptr %p.0, !400, !DIExpression(), !402)
    #dbg_value(i32 %hash.0, !399, !DIExpression(), !398)
  %0 = load i8, ptr %p.0, align 1, !dbg !405
  %conv = sext i8 %0 to i32, !dbg !405
  %cmp = icmp ne i32 %conv, 0, !dbg !407
  br i1 %cmp, label %for.body, label %for.end, !dbg !408

for.body:                                         ; preds = %for.cond
  %1 = load i8, ptr %p.0, align 1, !dbg !409
  %conv2 = zext i8 %1 to i32, !dbg !411
  %xor = xor i32 %hash.0, %conv2, !dbg !412
    #dbg_value(i32 %xor, !399, !DIExpression(), !398)
  %mul = mul i32 %xor, 16777619, !dbg !413
    #dbg_value(i32 %mul, !399, !DIExpression(), !398)
  br label %for.inc, !dbg !414

for.inc:                                          ; preds = %for.body
  %incdec.ptr = getelementptr inbounds nuw i8, ptr %p.0, i32 1, !dbg !415
    #dbg_value(ptr %incdec.ptr, !400, !DIExpression(), !402)
  br label %for.cond, !dbg !416, !llvm.loop !417

for.end:                                          ; preds = %for.cond
  ret i32 %hash.0, !dbg !419
}

; Function Attrs: nounwind
declare ptr @strncpy(ptr noundef, ptr noundef, i64 noundef) #3

; Function Attrs: nounwind willreturn memory(read)
declare i32 @strcmp(ptr noundef, ptr noundef) #5

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #6

declare void @qsort(ptr noundef, i64 noundef, i64 noundef, ptr noundef) #1

; Function Attrs: noinline nounwind uwtable
define internal i32 @by_count(ptr noundef %a, ptr noundef %b) #0 !dbg !420 {
entry:
    #dbg_value(ptr %a, !425, !DIExpression(), !426)
    #dbg_value(ptr %b, !427, !DIExpression(), !426)
    #dbg_value(ptr %a, !428, !DIExpression(), !426)
    #dbg_value(ptr %b, !429, !DIExpression(), !426)
  %count = getelementptr inbounds nuw %struct.entry, ptr %a, i32 0, i32 1, !dbg !430
  %0 = load i32, ptr %count, align 4, !dbg !430
  %count1 = getelementptr inbounds nuw %struct.entry, ptr %b, i32 0, i32 1, !dbg !432
  %1 = load i32, ptr %count1, align 4, !dbg !432
  %cmp = icmp ne i32 %0, %1, !dbg !433
  br i1 %cmp, label %if.then, label %if.end, !dbg !433

if.then:                                          ; preds = %entry
  %count2 = getelementptr inbounds nuw %struct.entry, ptr %b, i32 0, i32 1, !dbg !434
  %2 = load i32, ptr %count2, align 4, !dbg !434
  %count3 = getelementptr inbounds nuw %struct.entry, ptr %a, i32 0, i32 1, !dbg !436
  %3 = load i32, ptr %count3, align 4, !dbg !436
  %sub = sub nsw i32 %2, %3, !dbg !437
  br label %return, !dbg !438

if.end:                                           ; preds = %entry
  %first_seen = getelementptr inbounds nuw %struct.entry, ptr %a, i32 0, i32 2, !dbg !439
  %4 = load i32, ptr %first_seen, align 4, !dbg !439
  %first_seen4 = getelementptr inbounds nuw %struct.entry, ptr %b, i32 0, i32 2, !dbg !440
  %5 = load i32, ptr %first_seen4, align 4, !dbg !440
  %sub5 = sub nsw i32 %4, %5, !dbg !441
  br label %return, !dbg !442

return:                                           ; preds = %if.end, %if.then
  %retval.0 = phi i32 [ %sub, %if.then ], [ %sub5, %if.end ], !dbg !426
  ret i32 %retval.0, !dbg !443
}

; Function Attrs: noinline nounwind uwtable
define internal void @print_bar(i32 noundef %count, i32 noundef %widest) #0 !dbg !444 {
entry:
    #dbg_value(i32 %count, !447, !DIExpression(), !448)
    #dbg_value(i32 %widest, !449, !DIExpression(), !448)
  %cmp = icmp sgt i32 %widest, 0, !dbg !450
  br i1 %cmp, label %cond.true, label %cond.false, !dbg !451

cond.true:                                        ; preds = %entry
  %mul = mul nsw i32 %count, 30, !dbg !452
  %div = sdiv i32 %mul, %widest, !dbg !453
  br label %cond.end, !dbg !451

cond.false:                                       ; preds = %entry
  br label %cond.end, !dbg !451

cond.end:                                         ; preds = %cond.false, %cond.true
  %cond = phi i32 [ %div, %cond.true ], [ 0, %cond.false ], !dbg !451
    #dbg_value(i32 %cond, !454, !DIExpression(), !448)
    #dbg_value(i32 0, !455, !DIExpression(), !457)
  br label %for.cond, !dbg !458

for.cond:                                         ; preds = %for.inc, %cond.end
  %i.0 = phi i32 [ 0, %cond.end ], [ %inc, %for.inc ], !dbg !459
    #dbg_value(i32 %i.0, !455, !DIExpression(), !457)
  %cmp1 = icmp slt i32 %i.0, %cond, !dbg !460
  br i1 %cmp1, label %for.body, label %for.end, !dbg !462

for.body:                                         ; preds = %for.cond
  %call = call i32 @putchar(i32 noundef 35), !dbg !463
  br label %for.inc, !dbg !465

for.inc:                                          ; preds = %for.body
  %inc = add nsw i32 %i.0, 1, !dbg !466
    #dbg_value(i32 %inc, !455, !DIExpression(), !457)
  br label %for.cond, !dbg !467, !llvm.loop !468

for.end:                                          ; preds = %for.cond
  %call2 = call i32 @putchar(i32 noundef 10), !dbg !470
  ret void, !dbg !471
}

; Function Attrs: noinline nounwind uwtable
define internal ptr @longest(ptr noundef %entries, i32 noundef %n) #0 !dbg !472 {
entry:
    #dbg_value(ptr %entries, !475, !DIExpression(), !476)
    #dbg_value(i32 %n, !477, !DIExpression(), !476)
    #dbg_value(ptr null, !478, !DIExpression(), !476)
    #dbg_value(i64 0, !479, !DIExpression(), !476)
    #dbg_value(i32 0, !480, !DIExpression(), !482)
  br label %for.cond, !dbg !483

for.cond:                                         ; preds = %for.inc, %entry
  %best.0 = phi ptr [ null, %entry ], [ %best.1, %for.inc ], !dbg !476
  %best_length.0 = phi i64 [ 0, %entry ], [ %best_length.1, %for.inc ], !dbg !476
  %i.0 = phi i32 [ 0, %entry ], [ %inc, %for.inc ], !dbg !484
    #dbg_value(i32 %i.0, !480, !DIExpression(), !482)
    #dbg_value(i64 %best_length.0, !479, !DIExpression(), !476)
    #dbg_value(ptr %best.0, !478, !DIExpression(), !476)
  %cmp = icmp slt i32 %i.0, %n, !dbg !485
  br i1 %cmp, label %for.body, label %for.end, !dbg !487

for.body:                                         ; preds = %for.cond
  %idxprom = sext i32 %i.0 to i64, !dbg !488
  %arrayidx = getelementptr inbounds %struct.entry, ptr %entries, i64 %idxprom, !dbg !488
  %word = getelementptr inbounds nuw %struct.entry, ptr %arrayidx, i32 0, i32 0, !dbg !490
  %arraydecay = getelementptr inbounds [24 x i8], ptr %word, i64 0, i64 0, !dbg !488
  %call = call i64 @strlen(ptr noundef %arraydecay) #8, !dbg !491
    #dbg_value(i64 %call, !492, !DIExpression(), !493)
  %cmp1 = icmp ugt i64 %call, %best_length.0, !dbg !494
  br i1 %cmp1, label %if.then, label %if.end, !dbg !494

if.then:                                          ; preds = %for.body
  %idxprom2 = sext i32 %i.0 to i64, !dbg !496
  %arrayidx3 = getelementptr inbounds %struct.entry, ptr %entries, i64 %idxprom2, !dbg !496
    #dbg_value(ptr %arrayidx3, !478, !DIExpression(), !476)
    #dbg_value(i64 %call, !479, !DIExpression(), !476)
  br label %if.end, !dbg !498

if.end:                                           ; preds = %if.then, %for.body
  %best.1 = phi ptr [ %arrayidx3, %if.then ], [ %best.0, %for.body ], !dbg !476
  %best_length.1 = phi i64 [ %call, %if.then ], [ %best_length.0, %for.body ], !dbg !476
    #dbg_value(i64 %best_length.1, !479, !DIExpression(), !476)
    #dbg_value(ptr %best.1, !478, !DIExpression(), !476)
  br label %for.inc, !dbg !499

for.inc:                                          ; preds = %if.end
  %inc = add nsw i32 %i.0, 1, !dbg !500
    #dbg_value(i32 %inc, !480, !DIExpression(), !482)
  br label %for.cond, !dbg !501, !llvm.loop !502

for.end:                                          ; preds = %for.cond
  ret ptr %best.0, !dbg !504
}

; Function Attrs: noinline nounwind uwtable
define internal double @mean_length(ptr noundef %entries, i32 noundef %n) #0 !dbg !505 {
entry:
    #dbg_value(ptr %entries, !508, !DIExpression(), !509)
    #dbg_value(i32 %n, !510, !DIExpression(), !509)
    #dbg_value(i64 0, !511, !DIExpression(), !509)
    #dbg_value(i64 0, !512, !DIExpression(), !509)
    #dbg_value(i32 0, !513, !DIExpression(), !515)
  br label %for.cond, !dbg !516

for.cond:                                         ; preds = %for.inc, %entry
  %letters.0 = phi i64 [ 0, %entry ], [ %add, %for.inc ], !dbg !509
  %words.0 = phi i64 [ 0, %entry ], [ %add7, %for.inc ], !dbg !509
  %i.0 = phi i32 [ 0, %entry ], [ %inc, %for.inc ], !dbg !517
    #dbg_value(i32 %i.0, !513, !DIExpression(), !515)
    #dbg_value(i64 %words.0, !512, !DIExpression(), !509)
    #dbg_value(i64 %letters.0, !511, !DIExpression(), !509)
  %cmp = icmp slt i32 %i.0, %n, !dbg !518
  br i1 %cmp, label %for.body, label %for.end, !dbg !520

for.body:                                         ; preds = %for.cond
  %idxprom = sext i32 %i.0 to i64, !dbg !521
  %arrayidx = getelementptr inbounds %struct.entry, ptr %entries, i64 %idxprom, !dbg !521
  %word = getelementptr inbounds nuw %struct.entry, ptr %arrayidx, i32 0, i32 0, !dbg !523
  %arraydecay = getelementptr inbounds [24 x i8], ptr %word, i64 0, i64 0, !dbg !521
  %call = call i64 @strlen(ptr noundef %arraydecay) #8, !dbg !524
  %idxprom1 = sext i32 %i.0 to i64, !dbg !525
  %arrayidx2 = getelementptr inbounds %struct.entry, ptr %entries, i64 %idxprom1, !dbg !525
  %count = getelementptr inbounds nuw %struct.entry, ptr %arrayidx2, i32 0, i32 1, !dbg !526
  %0 = load i32, ptr %count, align 4, !dbg !526
  %conv = sext i32 %0 to i64, !dbg !525
  %mul = mul nsw i64 %call, %conv, !dbg !527
  %add = add nsw i64 %letters.0, %mul, !dbg !528
    #dbg_value(i64 %add, !511, !DIExpression(), !509)
  %idxprom3 = sext i32 %i.0 to i64, !dbg !529
  %arrayidx4 = getelementptr inbounds %struct.entry, ptr %entries, i64 %idxprom3, !dbg !529
  %count5 = getelementptr inbounds nuw %struct.entry, ptr %arrayidx4, i32 0, i32 1, !dbg !530
  %1 = load i32, ptr %count5, align 4, !dbg !530
  %conv6 = sext i32 %1 to i64, !dbg !529
  %add7 = add nsw i64 %words.0, %conv6, !dbg !531
    #dbg_value(i64 %add7, !512, !DIExpression(), !509)
  br label %for.inc, !dbg !532

for.inc:                                          ; preds = %for.body
  %inc = add nsw i32 %i.0, 1, !dbg !533
    #dbg_value(i32 %inc, !513, !DIExpression(), !515)
  br label %for.cond, !dbg !534, !llvm.loop !535

for.end:                                          ; preds = %for.cond
  %cmp8 = icmp sgt i64 %words.0, 0, !dbg !537
  br i1 %cmp8, label %cond.true, label %cond.false, !dbg !538

cond.true:                                        ; preds = %for.end
  %conv10 = sitofp i64 %letters.0 to double, !dbg !539
  %conv11 = sitofp i64 %words.0 to double, !dbg !540
  %div = fdiv double %conv10, %conv11, !dbg !541
  br label %cond.end, !dbg !538

cond.false:                                       ; preds = %for.end
  br label %cond.end, !dbg !538

cond.end:                                         ; preds = %cond.false, %cond.true
  %cond = phi double [ %div, %cond.true ], [ 0.000000e+00, %cond.false ], !dbg !538
  ret double %cond, !dbg !542
}

; Function Attrs: noinline nounwind uwtable
define internal i32 @singletons(ptr noundef %entries, i32 noundef %n) #0 !dbg !543 {
entry:
    #dbg_value(ptr %entries, !546, !DIExpression(), !547)
    #dbg_value(i32 %n, !548, !DIExpression(), !547)
    #dbg_value(i32 0, !549, !DIExpression(), !547)
  %sub = sub nsw i32 %n, 1, !dbg !550
    #dbg_value(i32 %sub, !552, !DIExpression(), !553)
  br label %for.cond, !dbg !554

for.cond:                                         ; preds = %for.inc, %entry
  %count.0 = phi i32 [ 0, %entry ], [ %inc, %for.inc ], !dbg !547
  %i.0 = phi i32 [ %sub, %entry ], [ %dec, %for.inc ], !dbg !555
    #dbg_value(i32 %i.0, !552, !DIExpression(), !553)
    #dbg_value(i32 %count.0, !549, !DIExpression(), !547)
  %cmp = icmp sge i32 %i.0, 0, !dbg !556
  br i1 %cmp, label %land.rhs, label %land.end, !dbg !558

land.rhs:                                         ; preds = %for.cond
  %idxprom = sext i32 %i.0 to i64, !dbg !559
  %arrayidx = getelementptr inbounds %struct.entry, ptr %entries, i64 %idxprom, !dbg !559
  %count1 = getelementptr inbounds nuw %struct.entry, ptr %arrayidx, i32 0, i32 1, !dbg !560
  %0 = load i32, ptr %count1, align 4, !dbg !560
  %cmp2 = icmp eq i32 %0, 1, !dbg !561
  br label %land.end

land.end:                                         ; preds = %land.rhs, %for.cond
  %1 = phi i1 [ false, %for.cond ], [ %cmp2, %land.rhs ], !dbg !562
  br i1 %1, label %for.body, label %for.end, !dbg !563

for.body:                                         ; preds = %land.end
  %inc = add nsw i32 %count.0, 1, !dbg !564
    #dbg_value(i32 %inc, !549, !DIExpression(), !547)
  br label %for.inc, !dbg !566

for.inc:                                          ; preds = %for.body
  %dec = add nsw i32 %i.0, -1, !dbg !567
    #dbg_value(i32 %dec, !552, !DIExpression(), !553)
  br label %for.cond, !dbg !568, !llvm.loop !569

for.end:                                          ; preds = %land.end
  ret i32 %count.0, !dbg !571
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
!109 = !DILocation(line: 189, column: 37, scope: !2)
!110 = !DILocation(line: 189, column: 17, scope: !2)
!111 = !DILocalVariable(name: "total", scope: !2, file: !3, line: 189, type: !6)
!112 = !DILocation(line: 0, scope: !2)
!113 = !DILocation(line: 190, column: 13, scope: !2)
!114 = !DILocalVariable(name: "n", scope: !2, file: !3, line: 190, type: !6)
!115 = !DILocation(line: 191, column: 5, scope: !2)
!116 = !DILocation(line: 192, column: 17, scope: !2)
!117 = !DILocalVariable(name: "foxes", scope: !2, file: !3, line: 192, type: !6)
!118 = !DILocation(line: 193, column: 16, scope: !2)
!119 = !DILocalVariable(name: "cats", scope: !2, file: !3, line: 193, type: !6)
!120 = !DILocation(line: 194, column: 5, scope: !2)
!121 = !DILocation(line: 195, column: 18, scope: !2)
!122 = !DILocation(line: 195, column: 22, scope: !2)
!123 = !DILocation(line: 195, column: 30, scope: !2)
!124 = !DILocation(line: 195, column: 12, scope: !2)
!125 = !DILocation(line: 195, column: 5, scope: !2)
!126 = distinct !DISubprogram(name: "table_init", scope: !3, file: !3, line: 39, type: !127, scopeLine: 39, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!127 = !DISubroutineType(types: !128)
!128 = !{null, !129}
!129 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !96, size: 64)
!130 = !DILocalVariable(name: "table", arg: 1, scope: !126, file: !3, line: 39, type: !129)
!131 = !DILocation(line: 0, scope: !126)
!132 = !DILocation(line: 40, column: 5, scope: !126)
!133 = !DILocation(line: 41, column: 1, scope: !126)
!134 = distinct !DISubprogram(name: "count_words", scope: !3, file: !3, line: 97, type: !135, scopeLine: 97, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!135 = !DISubroutineType(types: !136)
!136 = !{!6, !129, !74}
!137 = !DILocalVariable(name: "table", arg: 1, scope: !134, file: !3, line: 97, type: !129)
!138 = !DILocation(line: 0, scope: !134)
!139 = !DILocalVariable(name: "text", arg: 2, scope: !134, file: !3, line: 97, type: !74)
!140 = !DILocation(line: 97, column: 57, scope: !134)
!141 = !DILocalVariable(name: "word", scope: !134, file: !3, line: 98, type: !43)
!142 = !DILocation(line: 98, column: 10, scope: !134)
!143 = !DILocalVariable(name: "position", scope: !134, file: !3, line: 99, type: !6)
!144 = !DILocation(line: 100, column: 5, scope: !134)
!145 = !DILocation(line: 100, column: 29, scope: !134)
!146 = !DILocation(line: 100, column: 12, scope: !134)
!147 = !DILocation(line: 100, column: 35, scope: !134)
!148 = !DILocation(line: 101, column: 30, scope: !149)
!149 = distinct !DILexicalBlock(scope: !150, file: !3, line: 101, column: 13)
!150 = distinct !DILexicalBlock(scope: !134, file: !3, line: 100, column: 40)
!151 = !DILocation(line: 101, column: 13, scope: !149)
!152 = !DILocation(line: 101, column: 46, scope: !149)
!153 = !DILocation(line: 102, column: 21, scope: !154)
!154 = distinct !DILexicalBlock(scope: !149, file: !3, line: 101, column: 51)
!155 = !DILocation(line: 102, column: 13, scope: !154)
!156 = !DILocation(line: 103, column: 13, scope: !154)
!157 = !DILocation(line: 105, column: 17, scope: !150)
!158 = distinct !{!158, !144, !159, !160}
!159 = !DILocation(line: 106, column: 5, scope: !134)
!160 = !{!"llvm.loop.mustprogress"}
!161 = !DILocation(line: 107, column: 5, scope: !134)
!162 = distinct !DISubprogram(name: "collect", scope: !3, file: !3, line: 120, type: !163, scopeLine: 120, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!163 = !DISubroutineType(types: !164)
!164 = !{!6, !165, !167}
!165 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !166, size: 64)
!166 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !96)
!167 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !40, size: 64)
!168 = !DILocalVariable(name: "table", arg: 1, scope: !162, file: !3, line: 120, type: !165)
!169 = !DILocation(line: 0, scope: !162)
!170 = !DILocalVariable(name: "out", arg: 2, scope: !162, file: !3, line: 120, type: !167)
!171 = !DILocalVariable(name: "n", scope: !162, file: !3, line: 121, type: !6)
!172 = !DILocalVariable(name: "i", scope: !173, file: !3, line: 122, type: !6)
!173 = distinct !DILexicalBlock(scope: !162, file: !3, line: 122, column: 5)
!174 = !DILocation(line: 0, scope: !173)
!175 = !DILocation(line: 122, column: 10, scope: !173)
!176 = !DILocation(line: 122, scope: !173)
!177 = !DILocation(line: 122, column: 23, scope: !178)
!178 = distinct !DILexicalBlock(scope: !173, file: !3, line: 122, column: 5)
!179 = !DILocation(line: 122, column: 5, scope: !173)
!180 = !DILocation(line: 123, column: 20, scope: !181)
!181 = distinct !DILexicalBlock(scope: !182, file: !3, line: 123, column: 13)
!182 = distinct !DILexicalBlock(scope: !178, file: !3, line: 122, column: 42)
!183 = !DILocation(line: 123, column: 13, scope: !181)
!184 = !DILocation(line: 123, column: 29, scope: !181)
!185 = !DILocation(line: 123, column: 35, scope: !181)
!186 = !DILocation(line: 124, column: 18, scope: !187)
!187 = distinct !DILexicalBlock(scope: !181, file: !3, line: 123, column: 40)
!188 = !DILocation(line: 124, column: 13, scope: !187)
!189 = !DILocation(line: 124, column: 31, scope: !187)
!190 = !DILocation(line: 124, column: 24, scope: !187)
!191 = !DILocation(line: 125, column: 9, scope: !187)
!192 = !DILocation(line: 126, column: 5, scope: !182)
!193 = !DILocation(line: 122, column: 38, scope: !178)
!194 = !DILocation(line: 122, column: 5, scope: !178)
!195 = distinct !{!195, !179, !196, !160}
!196 = !DILocation(line: 126, column: 5, scope: !173)
!197 = !DILocation(line: 127, column: 16, scope: !162)
!198 = !DILocation(line: 127, column: 5, scope: !162)
!199 = !DILocation(line: 128, column: 5, scope: !162)
!200 = distinct !DISubprogram(name: "report", scope: !3, file: !3, line: 170, type: !201, scopeLine: 170, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!201 = !DISubroutineType(types: !202)
!202 = !{null, !203, !6, !6}
!203 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !204, size: 64)
!204 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !40)
!205 = !DILocalVariable(name: "entries", arg: 1, scope: !200, file: !3, line: 170, type: !203)
!206 = !DILocation(line: 0, scope: !200)
!207 = !DILocalVariable(name: "n", arg: 2, scope: !200, file: !3, line: 170, type: !6)
!208 = !DILocalVariable(name: "total", arg: 3, scope: !200, file: !3, line: 170, type: !6)
!209 = !DILocation(line: 171, column: 19, scope: !200)
!210 = !DILocation(line: 171, column: 17, scope: !200)
!211 = !DILocalVariable(name: "shown", scope: !200, file: !3, line: 171, type: !6)
!212 = !DILocation(line: 172, column: 5, scope: !200)
!213 = !DILocalVariable(name: "i", scope: !214, file: !3, line: 173, type: !6)
!214 = distinct !DILexicalBlock(scope: !200, file: !3, line: 173, column: 5)
!215 = !DILocation(line: 0, scope: !214)
!216 = !DILocation(line: 173, column: 10, scope: !214)
!217 = !DILocation(line: 173, scope: !214)
!218 = !DILocation(line: 173, column: 23, scope: !219)
!219 = distinct !DILexicalBlock(scope: !214, file: !3, line: 173, column: 5)
!220 = !DILocation(line: 173, column: 5, scope: !214)
!221 = !DILocation(line: 174, column: 30, scope: !222)
!222 = distinct !DILexicalBlock(scope: !219, file: !3, line: 173, column: 37)
!223 = !DILocation(line: 174, column: 41, scope: !222)
!224 = !DILocation(line: 174, column: 47, scope: !222)
!225 = !DILocation(line: 174, column: 58, scope: !222)
!226 = !DILocation(line: 174, column: 9, scope: !222)
!227 = !DILocation(line: 175, column: 19, scope: !222)
!228 = !DILocation(line: 175, column: 30, scope: !222)
!229 = !DILocation(line: 175, column: 37, scope: !222)
!230 = !DILocation(line: 175, column: 48, scope: !222)
!231 = !DILocation(line: 175, column: 9, scope: !222)
!232 = !DILocation(line: 176, column: 5, scope: !222)
!233 = !DILocation(line: 173, column: 33, scope: !219)
!234 = !DILocation(line: 173, column: 5, scope: !219)
!235 = distinct !{!235, !220, !236, !160}
!236 = !DILocation(line: 176, column: 5, scope: !214)
!237 = !DILocation(line: 177, column: 32, scope: !200)
!238 = !DILocalVariable(name: "word", scope: !200, file: !3, line: 177, type: !203)
!239 = !DILocation(line: 178, column: 14, scope: !240)
!240 = distinct !DILexicalBlock(scope: !200, file: !3, line: 178, column: 9)
!241 = !DILocation(line: 179, column: 44, scope: !242)
!242 = distinct !DILexicalBlock(scope: !240, file: !3, line: 178, column: 23)
!243 = !DILocation(line: 179, column: 38, scope: !242)
!244 = !DILocation(line: 179, column: 9, scope: !242)
!245 = !DILocation(line: 180, column: 5, scope: !242)
!246 = !DILocation(line: 181, column: 43, scope: !200)
!247 = !DILocation(line: 181, column: 5, scope: !200)
!248 = !DILocation(line: 182, column: 37, scope: !200)
!249 = !DILocation(line: 182, column: 5, scope: !200)
!250 = !DILocation(line: 183, column: 1, scope: !200)
!251 = distinct !DISubprogram(name: "table_lookup", scope: !3, file: !3, line: 64, type: !252, scopeLine: 64, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!252 = !DISubroutineType(types: !253)
!253 = !{!6, !165, !74}
!254 = !DILocalVariable(name: "table", arg: 1, scope: !251, file: !3, line: 64, type: !165)
!255 = !DILocation(line: 0, scope: !251)
!256 = !DILocalVariable(name: "word", arg: 2, scope: !251, file: !3, line: 64, type: !74)
!257 = !DILocation(line: 65, column: 26, scope: !251)
!258 = !DILocation(line: 65, column: 42, scope: !251)
!259 = !DILocalVariable(name: "index", scope: !251, file: !3, line: 65, type: !12)
!260 = !DILocalVariable(name: "probe", scope: !261, file: !3, line: 66, type: !6)
!261 = distinct !DILexicalBlock(scope: !251, file: !3, line: 66, column: 5)
!262 = !DILocation(line: 0, scope: !261)
!263 = !DILocation(line: 66, column: 10, scope: !261)
!264 = !DILocation(line: 66, scope: !261)
!265 = !DILocation(line: 66, column: 31, scope: !266)
!266 = distinct !DILexicalBlock(scope: !261, file: !3, line: 66, column: 5)
!267 = !DILocation(line: 66, column: 5, scope: !261)
!268 = !DILocation(line: 67, column: 44, scope: !269)
!269 = distinct !DILexicalBlock(scope: !266, file: !3, line: 66, column: 54)
!270 = !DILocation(line: 67, column: 37, scope: !269)
!271 = !DILocalVariable(name: "slot", scope: !269, file: !3, line: 67, type: !203)
!272 = !DILocation(line: 0, scope: !269)
!273 = !DILocation(line: 68, column: 19, scope: !274)
!274 = distinct !DILexicalBlock(scope: !269, file: !3, line: 68, column: 13)
!275 = !DILocation(line: 68, column: 25, scope: !274)
!276 = !DILocation(line: 69, column: 13, scope: !277)
!277 = distinct !DILexicalBlock(scope: !274, file: !3, line: 68, column: 31)
!278 = !DILocation(line: 71, column: 26, scope: !279)
!279 = distinct !DILexicalBlock(scope: !269, file: !3, line: 71, column: 13)
!280 = !DILocation(line: 71, column: 20, scope: !279)
!281 = !DILocation(line: 71, column: 13, scope: !279)
!282 = !DILocation(line: 71, column: 38, scope: !279)
!283 = !DILocation(line: 72, column: 26, scope: !284)
!284 = distinct !DILexicalBlock(scope: !279, file: !3, line: 71, column: 44)
!285 = !DILocation(line: 72, column: 13, scope: !284)
!286 = !DILocation(line: 74, column: 24, scope: !269)
!287 = !DILocation(line: 74, column: 29, scope: !269)
!288 = !DILocation(line: 75, column: 5, scope: !269)
!289 = !DILocation(line: 66, column: 50, scope: !266)
!290 = !DILocation(line: 66, column: 5, scope: !266)
!291 = distinct !{!291, !267, !292, !160}
!292 = !DILocation(line: 75, column: 5, scope: !261)
!293 = !DILocation(line: 76, column: 5, scope: !251)
!294 = !DILocation(line: 77, column: 1, scope: !251)
!295 = distinct !DISubprogram(name: "next_word", scope: !3, file: !3, line: 80, type: !296, scopeLine: 80, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!296 = !DISubroutineType(types: !297)
!297 = !{!6, !298, !299}
!298 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !74, size: 64)
!299 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !29, size: 64)
!300 = !DILocalVariable(name: "text", arg: 1, scope: !295, file: !3, line: 80, type: !298)
!301 = !DILocation(line: 0, scope: !295)
!302 = !DILocalVariable(name: "word", arg: 2, scope: !295, file: !3, line: 80, type: !299)
!303 = !DILocation(line: 81, column: 21, scope: !295)
!304 = !DILocalVariable(name: "p", scope: !295, file: !3, line: 81, type: !74)
!305 = !DILocation(line: 82, column: 5, scope: !295)
!306 = !DILocation(line: 82, column: 12, scope: !295)
!307 = !DILocation(line: 82, column: 15, scope: !295)
!308 = !DILocation(line: 82, column: 23, scope: !295)
!309 = !DILocation(line: 82, column: 27, scope: !295)
!310 = !DILocation(line: 82, column: 50, scope: !295)
!311 = !DILocation(line: 82, column: 26, scope: !295)
!312 = !DILocation(line: 83, column: 10, scope: !313)
!313 = distinct !DILexicalBlock(scope: !295, file: !3, line: 82, column: 55)
!314 = distinct !{!314, !305, !315, !160}
!315 = !DILocation(line: 84, column: 5, scope: !295)
!316 = !DILocalVariable(name: "length", scope: !295, file: !3, line: 85, type: !6)
!317 = !DILocation(line: 86, column: 5, scope: !295)
!318 = !DILocation(line: 86, column: 12, scope: !295)
!319 = !DILocation(line: 86, column: 35, scope: !295)
!320 = !DILocation(line: 87, column: 20, scope: !321)
!321 = distinct !DILexicalBlock(scope: !322, file: !3, line: 87, column: 13)
!322 = distinct !DILexicalBlock(scope: !295, file: !3, line: 86, column: 40)
!323 = !DILocation(line: 88, column: 59, scope: !324)
!324 = distinct !DILexicalBlock(scope: !321, file: !3, line: 87, column: 36)
!325 = !DILocation(line: 88, column: 44, scope: !324)
!326 = !DILocation(line: 88, column: 36, scope: !324)
!327 = !DILocation(line: 88, column: 30, scope: !324)
!328 = !DILocation(line: 88, column: 24, scope: !324)
!329 = !DILocation(line: 88, column: 13, scope: !324)
!330 = !DILocation(line: 88, column: 28, scope: !324)
!331 = !DILocation(line: 89, column: 9, scope: !324)
!332 = !DILocation(line: 90, column: 10, scope: !322)
!333 = distinct !{!333, !317, !334, !160}
!334 = !DILocation(line: 91, column: 5, scope: !295)
!335 = !DILocation(line: 92, column: 5, scope: !295)
!336 = !DILocation(line: 92, column: 18, scope: !295)
!337 = !DILocation(line: 93, column: 11, scope: !295)
!338 = !DILocation(line: 94, column: 5, scope: !295)
!339 = distinct !DISubprogram(name: "table_add", scope: !3, file: !3, line: 44, type: !340, scopeLine: 44, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!340 = !DISubroutineType(types: !341)
!341 = !{!6, !129, !74, !6}
!342 = !DILocalVariable(name: "table", arg: 1, scope: !339, file: !3, line: 44, type: !129)
!343 = !DILocation(line: 0, scope: !339)
!344 = !DILocalVariable(name: "word", arg: 2, scope: !339, file: !3, line: 44, type: !74)
!345 = !DILocalVariable(name: "position", arg: 3, scope: !339, file: !3, line: 44, type: !6)
!346 = !DILocation(line: 45, column: 26, scope: !339)
!347 = !DILocation(line: 45, column: 42, scope: !339)
!348 = !DILocalVariable(name: "index", scope: !339, file: !3, line: 45, type: !12)
!349 = !DILocalVariable(name: "probe", scope: !350, file: !3, line: 46, type: !6)
!350 = distinct !DILexicalBlock(scope: !339, file: !3, line: 46, column: 5)
!351 = !DILocation(line: 0, scope: !350)
!352 = !DILocation(line: 46, column: 10, scope: !350)
!353 = !DILocation(line: 46, scope: !350)
!354 = !DILocation(line: 46, column: 31, scope: !355)
!355 = distinct !DILexicalBlock(scope: !350, file: !3, line: 46, column: 5)
!356 = !DILocation(line: 46, column: 5, scope: !350)
!357 = !DILocation(line: 47, column: 38, scope: !358)
!358 = distinct !DILexicalBlock(scope: !355, file: !3, line: 46, column: 54)
!359 = !DILocation(line: 47, column: 31, scope: !358)
!360 = !DILocalVariable(name: "slot", scope: !358, file: !3, line: 47, type: !167)
!361 = !DILocation(line: 0, scope: !358)
!362 = !DILocation(line: 48, column: 19, scope: !363)
!363 = distinct !DILexicalBlock(scope: !358, file: !3, line: 48, column: 13)
!364 = !DILocation(line: 48, column: 25, scope: !363)
!365 = !DILocation(line: 49, column: 27, scope: !366)
!366 = distinct !DILexicalBlock(scope: !363, file: !3, line: 48, column: 31)
!367 = !DILocation(line: 49, column: 21, scope: !366)
!368 = !DILocation(line: 49, column: 13, scope: !366)
!369 = !DILocation(line: 50, column: 19, scope: !366)
!370 = !DILocation(line: 50, column: 25, scope: !366)
!371 = !DILocation(line: 51, column: 19, scope: !366)
!372 = !DILocation(line: 51, column: 30, scope: !366)
!373 = !DILocation(line: 52, column: 20, scope: !366)
!374 = !DILocation(line: 52, column: 24, scope: !366)
!375 = !DILocation(line: 53, column: 13, scope: !366)
!376 = !DILocation(line: 55, column: 26, scope: !377)
!377 = distinct !DILexicalBlock(scope: !358, file: !3, line: 55, column: 13)
!378 = !DILocation(line: 55, column: 20, scope: !377)
!379 = !DILocation(line: 55, column: 13, scope: !377)
!380 = !DILocation(line: 55, column: 38, scope: !377)
!381 = !DILocation(line: 56, column: 19, scope: !382)
!382 = distinct !DILexicalBlock(scope: !377, file: !3, line: 55, column: 44)
!383 = !DILocation(line: 56, column: 24, scope: !382)
!384 = !DILocation(line: 57, column: 13, scope: !382)
!385 = !DILocation(line: 59, column: 24, scope: !358)
!386 = !DILocation(line: 59, column: 29, scope: !358)
!387 = !DILocation(line: 60, column: 5, scope: !358)
!388 = !DILocation(line: 46, column: 50, scope: !355)
!389 = !DILocation(line: 46, column: 5, scope: !355)
!390 = distinct !{!390, !356, !391, !160}
!391 = !DILocation(line: 60, column: 5, scope: !350)
!392 = !DILocation(line: 61, column: 5, scope: !339)
!393 = !DILocation(line: 62, column: 1, scope: !339)
!394 = distinct !DISubprogram(name: "hash_word", scope: !3, file: !3, line: 30, type: !395, scopeLine: 30, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!395 = !DISubroutineType(types: !396)
!396 = !{!12, !74}
!397 = !DILocalVariable(name: "word", arg: 1, scope: !394, file: !3, line: 30, type: !74)
!398 = !DILocation(line: 0, scope: !394)
!399 = !DILocalVariable(name: "hash", scope: !394, file: !3, line: 31, type: !12)
!400 = !DILocalVariable(name: "p", scope: !401, file: !3, line: 32, type: !74)
!401 = distinct !DILexicalBlock(scope: !394, file: !3, line: 32, column: 5)
!402 = !DILocation(line: 0, scope: !401)
!403 = !DILocation(line: 32, column: 10, scope: !401)
!404 = !DILocation(line: 32, scope: !401)
!405 = !DILocation(line: 32, column: 32, scope: !406)
!406 = distinct !DILexicalBlock(scope: !401, file: !3, line: 32, column: 5)
!407 = !DILocation(line: 32, column: 35, scope: !406)
!408 = !DILocation(line: 32, column: 5, scope: !401)
!409 = !DILocation(line: 33, column: 32, scope: !410)
!410 = distinct !DILexicalBlock(scope: !406, file: !3, line: 32, column: 49)
!411 = !DILocation(line: 33, column: 17, scope: !410)
!412 = !DILocation(line: 33, column: 14, scope: !410)
!413 = !DILocation(line: 34, column: 14, scope: !410)
!414 = !DILocation(line: 35, column: 5, scope: !410)
!415 = !DILocation(line: 32, column: 45, scope: !406)
!416 = !DILocation(line: 32, column: 5, scope: !406)
!417 = distinct !{!417, !408, !418, !160}
!418 = !DILocation(line: 35, column: 5, scope: !401)
!419 = !DILocation(line: 36, column: 5, scope: !394)
!420 = distinct !DISubprogram(name: "by_count", scope: !3, file: !3, line: 111, type: !421, scopeLine: 111, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!421 = !DISubroutineType(types: !422)
!422 = !{!6, !423, !423}
!423 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !424, size: 64)
!424 = !DIDerivedType(tag: DW_TAG_const_type, baseType: null)
!425 = !DILocalVariable(name: "a", arg: 1, scope: !420, file: !3, line: 111, type: !423)
!426 = !DILocation(line: 0, scope: !420)
!427 = !DILocalVariable(name: "b", arg: 2, scope: !420, file: !3, line: 111, type: !423)
!428 = !DILocalVariable(name: "x", scope: !420, file: !3, line: 112, type: !203)
!429 = !DILocalVariable(name: "y", scope: !420, file: !3, line: 113, type: !203)
!430 = !DILocation(line: 114, column: 12, scope: !431)
!431 = distinct !DILexicalBlock(scope: !420, file: !3, line: 114, column: 9)
!432 = !DILocation(line: 114, column: 24, scope: !431)
!433 = !DILocation(line: 114, column: 18, scope: !431)
!434 = !DILocation(line: 115, column: 19, scope: !435)
!435 = distinct !DILexicalBlock(scope: !431, file: !3, line: 114, column: 31)
!436 = !DILocation(line: 115, column: 30, scope: !435)
!437 = !DILocation(line: 115, column: 25, scope: !435)
!438 = !DILocation(line: 115, column: 9, scope: !435)
!439 = !DILocation(line: 117, column: 15, scope: !420)
!440 = !DILocation(line: 117, column: 31, scope: !420)
!441 = !DILocation(line: 117, column: 26, scope: !420)
!442 = !DILocation(line: 117, column: 5, scope: !420)
!443 = !DILocation(line: 118, column: 1, scope: !420)
!444 = distinct !DISubprogram(name: "print_bar", scope: !3, file: !3, line: 162, type: !445, scopeLine: 162, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!445 = !DISubroutineType(types: !446)
!446 = !{null, !6, !6}
!447 = !DILocalVariable(name: "count", arg: 1, scope: !444, file: !3, line: 162, type: !6)
!448 = !DILocation(line: 0, scope: !444)
!449 = !DILocalVariable(name: "widest", arg: 2, scope: !444, file: !3, line: 162, type: !6)
!450 = !DILocation(line: 163, column: 24, scope: !444)
!451 = !DILocation(line: 163, column: 17, scope: !444)
!452 = !DILocation(line: 163, column: 36, scope: !444)
!453 = !DILocation(line: 163, column: 41, scope: !444)
!454 = !DILocalVariable(name: "width", scope: !444, file: !3, line: 163, type: !6)
!455 = !DILocalVariable(name: "i", scope: !456, file: !3, line: 164, type: !6)
!456 = distinct !DILexicalBlock(scope: !444, file: !3, line: 164, column: 5)
!457 = !DILocation(line: 0, scope: !456)
!458 = !DILocation(line: 164, column: 10, scope: !456)
!459 = !DILocation(line: 164, scope: !456)
!460 = !DILocation(line: 164, column: 23, scope: !461)
!461 = distinct !DILexicalBlock(scope: !456, file: !3, line: 164, column: 5)
!462 = !DILocation(line: 164, column: 5, scope: !456)
!463 = !DILocation(line: 165, column: 9, scope: !464)
!464 = distinct !DILexicalBlock(scope: !461, file: !3, line: 164, column: 37)
!465 = !DILocation(line: 166, column: 5, scope: !464)
!466 = !DILocation(line: 164, column: 33, scope: !461)
!467 = !DILocation(line: 164, column: 5, scope: !461)
!468 = distinct !{!468, !462, !469, !160}
!469 = !DILocation(line: 166, column: 5, scope: !456)
!470 = !DILocation(line: 167, column: 5, scope: !444)
!471 = !DILocation(line: 168, column: 1, scope: !444)
!472 = distinct !DISubprogram(name: "longest", scope: !3, file: !3, line: 141, type: !473, scopeLine: 141, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!473 = !DISubroutineType(types: !474)
!474 = !{!203, !203, !6}
!475 = !DILocalVariable(name: "entries", arg: 1, scope: !472, file: !3, line: 141, type: !203)
!476 = !DILocation(line: 0, scope: !472)
!477 = !DILocalVariable(name: "n", arg: 2, scope: !472, file: !3, line: 141, type: !6)
!478 = !DILocalVariable(name: "best", scope: !472, file: !3, line: 142, type: !203)
!479 = !DILocalVariable(name: "best_length", scope: !472, file: !3, line: 143, type: !30)
!480 = !DILocalVariable(name: "i", scope: !481, file: !3, line: 144, type: !6)
!481 = distinct !DILexicalBlock(scope: !472, file: !3, line: 144, column: 5)
!482 = !DILocation(line: 0, scope: !481)
!483 = !DILocation(line: 144, column: 10, scope: !481)
!484 = !DILocation(line: 144, scope: !481)
!485 = !DILocation(line: 144, column: 23, scope: !486)
!486 = distinct !DILexicalBlock(scope: !481, file: !3, line: 144, column: 5)
!487 = !DILocation(line: 144, column: 5, scope: !481)
!488 = !DILocation(line: 145, column: 32, scope: !489)
!489 = distinct !DILexicalBlock(scope: !486, file: !3, line: 144, column: 33)
!490 = !DILocation(line: 145, column: 43, scope: !489)
!491 = !DILocation(line: 145, column: 25, scope: !489)
!492 = !DILocalVariable(name: "length", scope: !489, file: !3, line: 145, type: !30)
!493 = !DILocation(line: 0, scope: !489)
!494 = !DILocation(line: 146, column: 20, scope: !495)
!495 = distinct !DILexicalBlock(scope: !489, file: !3, line: 146, column: 13)
!496 = !DILocation(line: 147, column: 21, scope: !497)
!497 = distinct !DILexicalBlock(scope: !495, file: !3, line: 146, column: 35)
!498 = !DILocation(line: 149, column: 9, scope: !497)
!499 = !DILocation(line: 150, column: 5, scope: !489)
!500 = !DILocation(line: 144, column: 29, scope: !486)
!501 = !DILocation(line: 144, column: 5, scope: !486)
!502 = distinct !{!502, !487, !503, !160}
!503 = !DILocation(line: 150, column: 5, scope: !481)
!504 = !DILocation(line: 151, column: 5, scope: !472)
!505 = distinct !DISubprogram(name: "mean_length", scope: !3, file: !3, line: 131, type: !506, scopeLine: 131, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!506 = !DISubroutineType(types: !507)
!507 = !{!35, !203, !6}
!508 = !DILocalVariable(name: "entries", arg: 1, scope: !505, file: !3, line: 131, type: !203)
!509 = !DILocation(line: 0, scope: !505)
!510 = !DILocalVariable(name: "n", arg: 2, scope: !505, file: !3, line: 131, type: !6)
!511 = !DILocalVariable(name: "letters", scope: !505, file: !3, line: 132, type: !34)
!512 = !DILocalVariable(name: "words", scope: !505, file: !3, line: 133, type: !34)
!513 = !DILocalVariable(name: "i", scope: !514, file: !3, line: 134, type: !6)
!514 = distinct !DILexicalBlock(scope: !505, file: !3, line: 134, column: 5)
!515 = !DILocation(line: 0, scope: !514)
!516 = !DILocation(line: 134, column: 10, scope: !514)
!517 = !DILocation(line: 134, scope: !514)
!518 = !DILocation(line: 134, column: 23, scope: !519)
!519 = distinct !DILexicalBlock(scope: !514, file: !3, line: 134, column: 5)
!520 = !DILocation(line: 134, column: 5, scope: !514)
!521 = !DILocation(line: 135, column: 33, scope: !522)
!522 = distinct !DILexicalBlock(scope: !519, file: !3, line: 134, column: 33)
!523 = !DILocation(line: 135, column: 44, scope: !522)
!524 = !DILocation(line: 135, column: 26, scope: !522)
!525 = !DILocation(line: 135, column: 52, scope: !522)
!526 = !DILocation(line: 135, column: 63, scope: !522)
!527 = !DILocation(line: 135, column: 50, scope: !522)
!528 = !DILocation(line: 135, column: 17, scope: !522)
!529 = !DILocation(line: 136, column: 18, scope: !522)
!530 = !DILocation(line: 136, column: 29, scope: !522)
!531 = !DILocation(line: 136, column: 15, scope: !522)
!532 = !DILocation(line: 137, column: 5, scope: !522)
!533 = !DILocation(line: 134, column: 29, scope: !519)
!534 = !DILocation(line: 134, column: 5, scope: !519)
!535 = distinct !{!535, !520, !536, !160}
!536 = !DILocation(line: 137, column: 5, scope: !514)
!537 = !DILocation(line: 138, column: 18, scope: !505)
!538 = !DILocation(line: 138, column: 12, scope: !505)
!539 = !DILocation(line: 138, column: 24, scope: !505)
!540 = !DILocation(line: 138, column: 42, scope: !505)
!541 = !DILocation(line: 138, column: 40, scope: !505)
!542 = !DILocation(line: 138, column: 5, scope: !505)
!543 = distinct !DISubprogram(name: "singletons", scope: !3, file: !3, line: 154, type: !544, scopeLine: 154, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!544 = !DISubroutineType(types: !545)
!545 = !{!6, !203, !6}
!546 = !DILocalVariable(name: "entries", arg: 1, scope: !543, file: !3, line: 154, type: !203)
!547 = !DILocation(line: 0, scope: !543)
!548 = !DILocalVariable(name: "n", arg: 2, scope: !543, file: !3, line: 154, type: !6)
!549 = !DILocalVariable(name: "count", scope: !543, file: !3, line: 155, type: !6)
!550 = !DILocation(line: 156, column: 20, scope: !551)
!551 = distinct !DILexicalBlock(scope: !543, file: !3, line: 156, column: 5)
!552 = !DILocalVariable(name: "i", scope: !551, file: !3, line: 156, type: !6)
!553 = !DILocation(line: 0, scope: !551)
!554 = !DILocation(line: 156, column: 10, scope: !551)
!555 = !DILocation(line: 156, scope: !551)
!556 = !DILocation(line: 156, column: 27, scope: !557)
!557 = distinct !DILexicalBlock(scope: !551, file: !3, line: 156, column: 5)
!558 = !DILocation(line: 156, column: 32, scope: !557)
!559 = !DILocation(line: 156, column: 35, scope: !557)
!560 = !DILocation(line: 156, column: 46, scope: !557)
!561 = !DILocation(line: 156, column: 52, scope: !557)
!562 = !DILocation(line: 0, scope: !557)
!563 = !DILocation(line: 156, column: 5, scope: !551)
!564 = !DILocation(line: 157, column: 14, scope: !565)
!565 = distinct !DILexicalBlock(scope: !557, file: !3, line: 156, column: 63)
!566 = !DILocation(line: 158, column: 5, scope: !565)
!567 = !DILocation(line: 156, column: 59, scope: !557)
!568 = !DILocation(line: 156, column: 5, scope: !557)
!569 = distinct !{!569, !563, !570, !160}
!570 = !DILocation(line: 158, column: 5, scope: !551)
!571 = !DILocation(line: 159, column: 5, scope: !543)
