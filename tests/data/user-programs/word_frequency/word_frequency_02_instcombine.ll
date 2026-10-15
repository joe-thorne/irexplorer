; ModuleID = '/workspace/out/word_frequency_01_mem2reg.ll'
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
  call void @table_init(ptr noundef nonnull @main.table), !dbg !108
  %0 = load ptr, ptr @passage, align 8, !dbg !109
  %call = call i32 @count_words(ptr noundef nonnull @main.table, ptr noundef %0), !dbg !110
    #dbg_value(i32 %call, !111, !DIExpression(), !112)
  %call1 = call i32 @collect(ptr noundef nonnull @main.table, ptr noundef nonnull @main.entries), !dbg !113
    #dbg_value(i32 %call1, !114, !DIExpression(), !112)
  call void @report(ptr noundef nonnull @main.entries, i32 noundef %call1, i32 noundef %call), !dbg !115
  %call2 = call i32 @table_lookup(ptr noundef nonnull @main.table, ptr noundef nonnull @.str), !dbg !116
    #dbg_value(i32 %call2, !117, !DIExpression(), !112)
  %call3 = call i32 @table_lookup(ptr noundef nonnull @main.table, ptr noundef nonnull @.str.1), !dbg !118
    #dbg_value(i32 %call3, !119, !DIExpression(), !112)
  %call4 = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.2, i32 noundef %call2, i32 noundef %call3) #7, !dbg !120
  %cmp = icmp sgt i32 %call2, 0, !dbg !121
  br i1 %cmp, label %land.rhs, label %land.end, !dbg !122

land.rhs:                                         ; preds = %entry
  %cmp5 = icmp ne i32 %call3, 0, !dbg !123
  %1 = zext i1 %cmp5 to i32, !dbg !124
  br label %land.end

land.end:                                         ; preds = %land.rhs, %entry
  %not. = phi i32 [ 1, %entry ], [ %1, %land.rhs ], !dbg !112
  ret i32 %not., !dbg !125
}

; Function Attrs: noinline nounwind uwtable
define internal void @table_init(ptr noundef %table) #0 !dbg !126 {
entry:
    #dbg_value(ptr %table, !130, !DIExpression(), !131)
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(8196) %table, i8 0, i64 8196, i1 false), !dbg !132
  ret void, !dbg !133
}

; Function Attrs: noinline nounwind uwtable
define internal i32 @count_words(ptr noundef %table, ptr noundef %text) #0 !dbg !134 {
entry:
  %text.addr = alloca ptr, align 8
  %word = alloca [24 x i8], align 16
    #dbg_value(ptr %table, !137, !DIExpression(), !138)
    #dbg_value(ptr %text, !139, !DIExpression(), !138)
  store ptr %text, ptr %text.addr, align 8
    #dbg_declare(ptr %word, !140, !DIExpression(), !141)
    #dbg_value(i32 0, !142, !DIExpression(), !138)
  br label %while.cond, !dbg !143

while.cond:                                       ; preds = %if.end, %entry
  %position.0 = phi i32 [ 0, %entry ], [ %inc, %if.end ], !dbg !138
    #dbg_value(i32 %position.0, !142, !DIExpression(), !138)
    #dbg_value(ptr %text.addr, !139, !DIExpression(DW_OP_deref), !138)
  %call = call i32 @next_word(ptr noundef nonnull %text.addr, ptr noundef nonnull %word), !dbg !144
  %cmp = icmp sgt i32 %call, 0, !dbg !145
  br i1 %cmp, label %while.body, label %while.end, !dbg !143

while.body:                                       ; preds = %while.cond
  %call2 = call i32 @table_add(ptr noundef %table, ptr noundef nonnull %word, i32 noundef %position.0), !dbg !146
  %cmp3 = icmp slt i32 %call2, 0, !dbg !149
  br i1 %cmp3, label %if.then, label %if.end, !dbg !149

if.then:                                          ; preds = %while.body
  %0 = load ptr, ptr @stderr, align 8, !dbg !150
  %call4 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %0, ptr noundef nonnull @.str.3, i32 noundef %position.0) #8, !dbg !152
  br label %while.end, !dbg !153

if.end:                                           ; preds = %while.body
  %inc = add nuw nsw i32 %position.0, 1, !dbg !154
    #dbg_value(i32 %inc, !142, !DIExpression(), !138)
  br label %while.cond, !dbg !143, !llvm.loop !155

while.end:                                        ; preds = %if.then, %while.cond
  ret i32 %position.0, !dbg !158
}

; Function Attrs: noinline nounwind uwtable
define internal i32 @collect(ptr noundef %table, ptr noundef %out) #0 !dbg !159 {
entry:
    #dbg_value(ptr %table, !165, !DIExpression(), !166)
    #dbg_value(ptr %out, !167, !DIExpression(), !166)
    #dbg_value(i32 0, !168, !DIExpression(), !166)
    #dbg_value(i32 0, !169, !DIExpression(), !171)
  br label %for.cond, !dbg !172

for.cond:                                         ; preds = %for.inc, %entry
  %n.0 = phi i32 [ 0, %entry ], [ %n.1, %for.inc ], !dbg !166
  %i.0 = phi i32 [ 0, %entry ], [ %inc7, %for.inc ], !dbg !173
    #dbg_value(i32 %i.0, !169, !DIExpression(), !171)
    #dbg_value(i32 %n.0, !168, !DIExpression(), !166)
  %cmp = icmp samesign ult i32 %i.0, 256, !dbg !174
  br i1 %cmp, label %for.body, label %for.end, !dbg !176

for.body:                                         ; preds = %for.cond
  %idxprom = zext nneg i32 %i.0 to i64, !dbg !177
  %arrayidx = getelementptr inbounds nuw %struct.entry, ptr %table, i64 %idxprom, !dbg !177
  %count = getelementptr inbounds nuw i8, ptr %arrayidx, i64 24, !dbg !180
  %0 = load i32, ptr %count, align 4, !dbg !180
  %cmp1 = icmp sgt i32 %0, 0, !dbg !181
  br i1 %cmp1, label %if.then, label %if.end, !dbg !181

if.then:                                          ; preds = %for.body
  %inc = add nsw i32 %n.0, 1, !dbg !182
    #dbg_value(i32 %inc, !168, !DIExpression(), !166)
  %idxprom2 = sext i32 %n.0 to i64, !dbg !184
  %arrayidx3 = getelementptr inbounds %struct.entry, ptr %out, i64 %idxprom2, !dbg !184
  %idxprom5 = zext nneg i32 %i.0 to i64, !dbg !185
  %arrayidx6 = getelementptr inbounds nuw %struct.entry, ptr %table, i64 %idxprom5, !dbg !185
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 4 dereferenceable(32) %arrayidx3, ptr noundef nonnull align 4 dereferenceable(32) %arrayidx6, i64 32, i1 false), !dbg !185
  br label %if.end, !dbg !186

if.end:                                           ; preds = %if.then, %for.body
  %n.1 = phi i32 [ %inc, %if.then ], [ %n.0, %for.body ], !dbg !166
    #dbg_value(i32 %n.1, !168, !DIExpression(), !166)
  br label %for.inc, !dbg !187

for.inc:                                          ; preds = %if.end
  %inc7 = add nuw nsw i32 %i.0, 1, !dbg !188
    #dbg_value(i32 %inc7, !169, !DIExpression(), !171)
  br label %for.cond, !dbg !189, !llvm.loop !190

for.end:                                          ; preds = %for.cond
  %conv = sext i32 %n.0 to i64, !dbg !192
  call void @qsort(ptr noundef %out, i64 noundef %conv, i64 noundef 32, ptr noundef nonnull @by_count) #7, !dbg !193
  ret i32 %n.0, !dbg !194
}

; Function Attrs: noinline nounwind uwtable
define internal void @report(ptr noundef %entries, i32 noundef %n, i32 noundef %total) #0 !dbg !195 {
entry:
    #dbg_value(ptr %entries, !200, !DIExpression(), !201)
    #dbg_value(i32 %n, !202, !DIExpression(), !201)
    #dbg_value(i32 %total, !203, !DIExpression(), !201)
  %cmp = icmp slt i32 %n, 8, !dbg !204
  br i1 %cmp, label %cond.true, label %cond.false, !dbg !205

cond.true:                                        ; preds = %entry
  br label %cond.end, !dbg !205

cond.false:                                       ; preds = %entry
  br label %cond.end, !dbg !205

cond.end:                                         ; preds = %cond.false, %cond.true
  %cond = phi i32 [ %n, %cond.true ], [ 8, %cond.false ], !dbg !205
    #dbg_value(i32 %cond, !206, !DIExpression(), !201)
  %call = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.5, i32 noundef %total, i32 noundef %n) #7, !dbg !207
    #dbg_value(i32 0, !208, !DIExpression(), !210)
  br label %for.cond, !dbg !211

for.cond:                                         ; preds = %for.inc, %cond.end
  %i.0 = phi i32 [ 0, %cond.end ], [ %inc, %for.inc ], !dbg !212
    #dbg_value(i32 %i.0, !208, !DIExpression(), !210)
  %cmp1 = icmp slt i32 %i.0, %cond, !dbg !213
  br i1 %cmp1, label %for.body, label %for.end, !dbg !215

for.body:                                         ; preds = %for.cond
  %idxprom = zext nneg i32 %i.0 to i64, !dbg !216
  %arrayidx = getelementptr inbounds nuw %struct.entry, ptr %entries, i64 %idxprom, !dbg !216
  %idxprom2 = zext nneg i32 %i.0 to i64, !dbg !218
  %arrayidx3 = getelementptr inbounds nuw %struct.entry, ptr %entries, i64 %idxprom2, !dbg !218
  %count = getelementptr inbounds nuw i8, ptr %arrayidx3, i64 24, !dbg !219
  %0 = load i32, ptr %count, align 4, !dbg !219
  %call4 = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.6, ptr noundef %arrayidx, i32 noundef %0) #7, !dbg !220
  %idxprom5 = zext nneg i32 %i.0 to i64, !dbg !221
  %arrayidx6 = getelementptr inbounds nuw %struct.entry, ptr %entries, i64 %idxprom5, !dbg !221
  %count7 = getelementptr inbounds nuw i8, ptr %arrayidx6, i64 24, !dbg !222
  %1 = load i32, ptr %count7, align 4, !dbg !222
  %count9 = getelementptr inbounds nuw i8, ptr %entries, i64 24, !dbg !223
  %2 = load i32, ptr %count9, align 4, !dbg !223
  call void @print_bar(i32 noundef %1, i32 noundef %2), !dbg !224
  br label %for.inc, !dbg !225

for.inc:                                          ; preds = %for.body
  %inc = add nuw nsw i32 %i.0, 1, !dbg !226
    #dbg_value(i32 %inc, !208, !DIExpression(), !210)
  br label %for.cond, !dbg !227, !llvm.loop !228

for.end:                                          ; preds = %for.cond
  %call11 = call ptr @longest(ptr noundef %entries, i32 noundef %n), !dbg !230
    #dbg_value(ptr %call11, !231, !DIExpression(), !201)
  %cmp12.not = icmp eq ptr %call11, null, !dbg !232
  br i1 %cmp12.not, label %if.end, label %if.then, !dbg !232

if.then:                                          ; preds = %for.end
  %call15 = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.7, ptr noundef nonnull %call11) #7, !dbg !234
  br label %if.end, !dbg !236

if.end:                                           ; preds = %if.then, %for.end
  %call16 = call double @mean_length(ptr noundef %entries, i32 noundef %n), !dbg !237
  %call17 = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.8, double noundef %call16) #7, !dbg !238
  %call18 = call i32 @singletons(ptr noundef %entries, i32 noundef %n), !dbg !239
  %call19 = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.9, i32 noundef %call18) #7, !dbg !240
  ret void, !dbg !241
}

; Function Attrs: noinline nounwind uwtable
define internal i32 @table_lookup(ptr noundef %table, ptr noundef %word) #0 !dbg !242 {
entry:
    #dbg_value(ptr %table, !245, !DIExpression(), !246)
    #dbg_value(ptr %word, !247, !DIExpression(), !246)
  %call = call i32 @hash_word(ptr noundef %word), !dbg !248
    #dbg_value(i32 %call, !249, !DIExpression(DW_OP_constu, 255, DW_OP_and, DW_OP_stack_value), !246)
    #dbg_value(i32 0, !250, !DIExpression(), !252)
  br label %for.cond, !dbg !253

for.cond:                                         ; preds = %for.inc, %entry
  %index.0.in = phi i32 [ %call, %entry ], [ %add, %for.inc ]
  %probe.0 = phi i32 [ 0, %entry ], [ %inc, %for.inc ], !dbg !254
  %index.0 = and i32 %index.0.in, 255, !dbg !246
    #dbg_value(i32 %probe.0, !250, !DIExpression(), !252)
    #dbg_value(i32 %index.0, !249, !DIExpression(), !246)
  %cmp = icmp samesign ult i32 %probe.0, 256, !dbg !255
  br i1 %cmp, label %for.body, label %for.end, !dbg !257

for.body:                                         ; preds = %for.cond
  %idxprom = zext nneg i32 %index.0 to i64, !dbg !258
  %arrayidx = getelementptr inbounds nuw %struct.entry, ptr %table, i64 %idxprom, !dbg !258
    #dbg_value(ptr %arrayidx, !260, !DIExpression(), !261)
  %count = getelementptr inbounds nuw i8, ptr %arrayidx, i64 24, !dbg !262
  %0 = load i32, ptr %count, align 4, !dbg !262
  %cmp1 = icmp eq i32 %0, 0, !dbg !264
  br i1 %cmp1, label %if.then, label %if.end, !dbg !264

if.then:                                          ; preds = %for.body
  br label %return, !dbg !265

if.end:                                           ; preds = %for.body
  %call3 = call i32 @strcmp(ptr noundef nonnull dereferenceable(1) %arrayidx, ptr noundef nonnull dereferenceable(1) %word) #9, !dbg !267
  %cmp4 = icmp eq i32 %call3, 0, !dbg !269
  br i1 %cmp4, label %if.then5, label %if.end7, !dbg !269

if.then5:                                         ; preds = %if.end
  %count6 = getelementptr inbounds nuw i8, ptr %arrayidx, i64 24, !dbg !270
  %1 = load i32, ptr %count6, align 4, !dbg !270
  br label %return, !dbg !272

if.end7:                                          ; preds = %if.end
    #dbg_value(i32 poison, !249, !DIExpression(), !246)
  br label %for.inc, !dbg !273

for.inc:                                          ; preds = %if.end7
  %add = add nuw nsw i32 %index.0, 1, !dbg !274
    #dbg_value(i32 %add, !249, !DIExpression(DW_OP_constu, 255, DW_OP_and, DW_OP_stack_value), !246)
  %inc = add nuw nsw i32 %probe.0, 1, !dbg !275
    #dbg_value(i32 %inc, !250, !DIExpression(), !252)
  br label %for.cond, !dbg !276, !llvm.loop !277

for.end:                                          ; preds = %for.cond
  br label %return, !dbg !279

return:                                           ; preds = %for.end, %if.then5, %if.then
  %retval.0 = phi i32 [ 0, %if.then ], [ %1, %if.then5 ], [ 0, %for.end ], !dbg !246
  ret i32 %retval.0, !dbg !280
}

declare i32 @printf(ptr noundef, ...) #1

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr writeonly captures(none), i8, i64, i1 immarg) #2

; Function Attrs: noinline nounwind uwtable
define internal i32 @next_word(ptr noundef %text, ptr noundef %word) #0 !dbg !281 {
entry:
    #dbg_value(ptr %text, !286, !DIExpression(), !287)
    #dbg_value(ptr %word, !288, !DIExpression(), !287)
  %0 = load ptr, ptr %text, align 8, !dbg !289
    #dbg_value(ptr %0, !290, !DIExpression(), !287)
  br label %while.cond, !dbg !291

while.cond:                                       ; preds = %while.body, %entry
  %p.0 = phi ptr [ %0, %entry ], [ %incdec.ptr, %while.body ], !dbg !287
    #dbg_value(ptr %p.0, !290, !DIExpression(), !287)
  %1 = load i8, ptr %p.0, align 1, !dbg !292
  %cmp.not = icmp eq i8 %1, 0, !dbg !293
  br i1 %cmp.not, label %land.end, label %land.rhs, !dbg !294

land.rhs:                                         ; preds = %while.cond
  %call = call ptr @__ctype_b_loc() #10, !dbg !295
  %2 = load ptr, ptr %call, align 8, !dbg !295
  %3 = load i8, ptr %p.0, align 1, !dbg !296
  %idxprom = zext i8 %3 to i64, !dbg !295
  %arrayidx = getelementptr inbounds nuw i16, ptr %2, i64 %idxprom, !dbg !295
  %4 = load i16, ptr %arrayidx, align 2, !dbg !295
  %5 = and i16 %4, 1024, !dbg !295
  %tobool.not = icmp eq i16 %5, 0, !dbg !297
  br label %land.end

land.end:                                         ; preds = %land.rhs, %while.cond
  %6 = phi i1 [ false, %while.cond ], [ %tobool.not, %land.rhs ], !dbg !287
  br i1 %6, label %while.body, label %while.end, !dbg !291

while.body:                                       ; preds = %land.end
  %incdec.ptr = getelementptr inbounds nuw i8, ptr %p.0, i64 1, !dbg !298
    #dbg_value(ptr %incdec.ptr, !290, !DIExpression(), !287)
  br label %while.cond, !dbg !291, !llvm.loop !300

while.end:                                        ; preds = %land.end
    #dbg_value(i32 0, !302, !DIExpression(), !287)
  br label %while.cond4, !dbg !303

while.cond4:                                      ; preds = %if.end, %while.end
  %p.1 = phi ptr [ %p.0, %while.end ], [ %incdec.ptr20, %if.end ], !dbg !287
  %length.0 = phi i32 [ 0, %while.end ], [ %length.1, %if.end ], !dbg !287
    #dbg_value(i32 %length.0, !302, !DIExpression(), !287)
    #dbg_value(ptr %p.1, !290, !DIExpression(), !287)
  %call5 = call ptr @__ctype_b_loc() #10, !dbg !304
  %7 = load ptr, ptr %call5, align 8, !dbg !304
  %8 = load i8, ptr %p.1, align 1, !dbg !305
  %idxprom7 = zext i8 %8 to i64, !dbg !304
  %arrayidx8 = getelementptr inbounds nuw i16, ptr %7, i64 %idxprom7, !dbg !304
  %9 = load i16, ptr %arrayidx8, align 2, !dbg !304
  %10 = and i16 %9, 1024, !dbg !304
  %tobool11.not = icmp eq i16 %10, 0, !dbg !303
  br i1 %tobool11.not, label %while.end21, label %while.body12, !dbg !303

while.body12:                                     ; preds = %while.cond4
  %cmp13 = icmp slt i32 %length.0, 23, !dbg !306
  br i1 %cmp13, label %if.then, label %if.end, !dbg !306

if.then:                                          ; preds = %while.body12
  %11 = load i8, ptr %p.1, align 1, !dbg !309
  %conv15 = zext i8 %11 to i32, !dbg !311
  %call16 = call i32 @tolower(i32 noundef %conv15) #9, !dbg !312
  %conv17 = trunc i32 %call16 to i8, !dbg !313
  %inc = add nsw i32 %length.0, 1, !dbg !314
    #dbg_value(i32 %inc, !302, !DIExpression(), !287)
  %idxprom18 = sext i32 %length.0 to i64, !dbg !315
  %arrayidx19 = getelementptr inbounds i8, ptr %word, i64 %idxprom18, !dbg !315
  store i8 %conv17, ptr %arrayidx19, align 1, !dbg !316
  br label %if.end, !dbg !317

if.end:                                           ; preds = %if.then, %while.body12
  %length.1 = phi i32 [ %inc, %if.then ], [ %length.0, %while.body12 ], !dbg !287
    #dbg_value(i32 %length.1, !302, !DIExpression(), !287)
  %incdec.ptr20 = getelementptr inbounds nuw i8, ptr %p.1, i64 1, !dbg !318
    #dbg_value(ptr %incdec.ptr20, !290, !DIExpression(), !287)
  br label %while.cond4, !dbg !303, !llvm.loop !319

while.end21:                                      ; preds = %while.cond4
  %idxprom22 = sext i32 %length.0 to i64, !dbg !321
  %arrayidx23 = getelementptr inbounds i8, ptr %word, i64 %idxprom22, !dbg !321
  store i8 0, ptr %arrayidx23, align 1, !dbg !322
  store ptr %p.1, ptr %text, align 8, !dbg !323
  ret i32 %length.0, !dbg !324
}

; Function Attrs: noinline nounwind uwtable
define internal i32 @table_add(ptr noundef %table, ptr noundef %word, i32 noundef %position) #0 !dbg !325 {
entry:
    #dbg_value(ptr %table, !328, !DIExpression(), !329)
    #dbg_value(ptr %word, !330, !DIExpression(), !329)
    #dbg_value(i32 %position, !331, !DIExpression(), !329)
  %call = call i32 @hash_word(ptr noundef %word), !dbg !332
    #dbg_value(i32 %call, !333, !DIExpression(DW_OP_constu, 255, DW_OP_and, DW_OP_stack_value), !329)
    #dbg_value(i32 0, !334, !DIExpression(), !336)
  br label %for.cond, !dbg !337

for.cond:                                         ; preds = %for.inc, %entry
  %index.0.in = phi i32 [ %call, %entry ], [ %add, %for.inc ]
  %probe.0 = phi i32 [ 0, %entry ], [ %inc14, %for.inc ], !dbg !338
  %index.0 = and i32 %index.0.in, 255, !dbg !329
    #dbg_value(i32 %probe.0, !334, !DIExpression(), !336)
    #dbg_value(i32 %index.0, !333, !DIExpression(), !329)
  %cmp = icmp samesign ult i32 %probe.0, 256, !dbg !339
  br i1 %cmp, label %for.body, label %for.end, !dbg !341

for.body:                                         ; preds = %for.cond
  %idxprom = zext nneg i32 %index.0 to i64, !dbg !342
  %arrayidx = getelementptr inbounds nuw %struct.entry, ptr %table, i64 %idxprom, !dbg !342
    #dbg_value(ptr %arrayidx, !344, !DIExpression(), !345)
  %count = getelementptr inbounds nuw i8, ptr %arrayidx, i64 24, !dbg !346
  %0 = load i32, ptr %count, align 4, !dbg !346
  %cmp1 = icmp eq i32 %0, 0, !dbg !348
  br i1 %cmp1, label %if.then, label %if.end, !dbg !348

if.then:                                          ; preds = %for.body
  %call3 = call ptr @strncpy(ptr noundef nonnull dereferenceable(1) %arrayidx, ptr noundef nonnull dereferenceable(1) %word, i64 noundef 23) #7, !dbg !349
  %count4 = getelementptr inbounds nuw i8, ptr %arrayidx, i64 24, !dbg !351
  store i32 1, ptr %count4, align 4, !dbg !352
  %first_seen = getelementptr inbounds nuw i8, ptr %arrayidx, i64 28, !dbg !353
  store i32 %position, ptr %first_seen, align 4, !dbg !354
  %used = getelementptr inbounds nuw i8, ptr %table, i64 8192, !dbg !355
  %1 = load i32, ptr %used, align 4, !dbg !356
  %inc = add nsw i32 %1, 1, !dbg !356
  store i32 %inc, ptr %used, align 4, !dbg !356
  br label %return, !dbg !357

if.end:                                           ; preds = %for.body
  %call7 = call i32 @strcmp(ptr noundef nonnull dereferenceable(1) %arrayidx, ptr noundef nonnull dereferenceable(1) %word) #9, !dbg !358
  %cmp8 = icmp eq i32 %call7, 0, !dbg !360
  br i1 %cmp8, label %if.then9, label %if.end12, !dbg !360

if.then9:                                         ; preds = %if.end
  %count10 = getelementptr inbounds nuw i8, ptr %arrayidx, i64 24, !dbg !361
  %2 = load i32, ptr %count10, align 4, !dbg !363
  %inc11 = add nsw i32 %2, 1, !dbg !363
  store i32 %inc11, ptr %count10, align 4, !dbg !363
  br label %return, !dbg !364

if.end12:                                         ; preds = %if.end
    #dbg_value(i32 poison, !333, !DIExpression(), !329)
  br label %for.inc, !dbg !365

for.inc:                                          ; preds = %if.end12
  %add = add nuw nsw i32 %index.0, 1, !dbg !366
    #dbg_value(i32 %add, !333, !DIExpression(DW_OP_constu, 255, DW_OP_and, DW_OP_stack_value), !329)
  %inc14 = add nuw nsw i32 %probe.0, 1, !dbg !367
    #dbg_value(i32 %inc14, !334, !DIExpression(), !336)
  br label %for.cond, !dbg !368, !llvm.loop !369

for.end:                                          ; preds = %for.cond
  br label %return, !dbg !371

return:                                           ; preds = %for.end, %if.then9, %if.then
  %retval.0 = phi i32 [ 1, %if.then ], [ 0, %if.then9 ], [ -1, %for.end ], !dbg !329
  ret i32 %retval.0, !dbg !372
}

; Function Attrs: nounwind
declare i32 @fprintf(ptr noundef, ptr noundef, ...) #3

; Function Attrs: nounwind willreturn memory(none)
declare ptr @__ctype_b_loc() #4

; Function Attrs: nounwind willreturn memory(read)
declare i32 @tolower(i32 noundef) #5

; Function Attrs: noinline nounwind uwtable
define internal i32 @hash_word(ptr noundef %word) #0 !dbg !373 {
entry:
    #dbg_value(ptr %word, !376, !DIExpression(), !377)
    #dbg_value(i32 -2128831035, !378, !DIExpression(), !377)
    #dbg_value(ptr %word, !379, !DIExpression(), !381)
  br label %for.cond, !dbg !382

for.cond:                                         ; preds = %for.inc, %entry
  %hash.0 = phi i32 [ -2128831035, %entry ], [ %mul, %for.inc ], !dbg !377
  %p.0 = phi ptr [ %word, %entry ], [ %incdec.ptr, %for.inc ], !dbg !383
    #dbg_value(ptr %p.0, !379, !DIExpression(), !381)
    #dbg_value(i32 %hash.0, !378, !DIExpression(), !377)
  %0 = load i8, ptr %p.0, align 1, !dbg !384
  %cmp.not = icmp eq i8 %0, 0, !dbg !386
  br i1 %cmp.not, label %for.end, label %for.body, !dbg !387

for.body:                                         ; preds = %for.cond
    #dbg_value(!DIArgList(i32 poison, i8 poison), !378, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_LLVM_convert, 32, DW_ATE_unsigned, DW_OP_xor, DW_OP_stack_value), !377)
    #dbg_value(!DIArgList(i32 poison, i8 poison), !378, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_LLVM_convert, 32, DW_ATE_unsigned, DW_OP_xor, DW_OP_constu, 16777619, DW_OP_mul, DW_OP_stack_value), !377)
  br label %for.inc, !dbg !388

for.inc:                                          ; preds = %for.body
  %1 = load i8, ptr %p.0, align 1, !dbg !390
    #dbg_value(!DIArgList(i32 %hash.0, i8 %1), !378, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_LLVM_convert, 32, DW_ATE_unsigned, DW_OP_xor, DW_OP_constu, 16777619, DW_OP_mul, DW_OP_stack_value), !377)
  %conv2 = zext i8 %1 to i32, !dbg !391
    #dbg_value(!DIArgList(i32 %hash.0, i32 %conv2), !378, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_xor, DW_OP_constu, 16777619, DW_OP_mul, DW_OP_stack_value), !377)
  %xor = xor i32 %hash.0, %conv2, !dbg !392
    #dbg_value(i32 %xor, !378, !DIExpression(DW_OP_constu, 16777619, DW_OP_mul, DW_OP_stack_value), !377)
  %mul = mul i32 %xor, 16777619, !dbg !393
    #dbg_value(i32 %mul, !378, !DIExpression(), !377)
  %incdec.ptr = getelementptr inbounds nuw i8, ptr %p.0, i64 1, !dbg !394
    #dbg_value(ptr %incdec.ptr, !379, !DIExpression(), !381)
  br label %for.cond, !dbg !395, !llvm.loop !396

for.end:                                          ; preds = %for.cond
  ret i32 %hash.0, !dbg !398
}

; Function Attrs: nounwind
declare ptr @strncpy(ptr noundef, ptr noundef, i64 noundef) #3

; Function Attrs: nounwind willreturn memory(read)
declare i32 @strcmp(ptr noundef, ptr noundef) #5

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #6

declare void @qsort(ptr noundef, i64 noundef, i64 noundef, ptr noundef) #1

; Function Attrs: noinline nounwind uwtable
define internal i32 @by_count(ptr noundef %a, ptr noundef %b) #0 !dbg !399 {
entry:
    #dbg_value(ptr %a, !404, !DIExpression(), !405)
    #dbg_value(ptr %b, !406, !DIExpression(), !405)
    #dbg_value(ptr %a, !407, !DIExpression(), !405)
    #dbg_value(ptr %b, !408, !DIExpression(), !405)
  %count = getelementptr inbounds nuw i8, ptr %a, i64 24, !dbg !409
  %0 = load i32, ptr %count, align 4, !dbg !409
  %count1 = getelementptr inbounds nuw i8, ptr %b, i64 24, !dbg !411
  %1 = load i32, ptr %count1, align 4, !dbg !411
  %cmp.not = icmp eq i32 %0, %1, !dbg !412
  br i1 %cmp.not, label %if.end, label %if.then, !dbg !412

if.then:                                          ; preds = %entry
  %count2 = getelementptr inbounds nuw i8, ptr %b, i64 24, !dbg !413
  %2 = load i32, ptr %count2, align 4, !dbg !413
  %count3 = getelementptr inbounds nuw i8, ptr %a, i64 24, !dbg !415
  %3 = load i32, ptr %count3, align 4, !dbg !415
  %sub = sub nsw i32 %2, %3, !dbg !416
  br label %return, !dbg !417

if.end:                                           ; preds = %entry
  %first_seen = getelementptr inbounds nuw i8, ptr %a, i64 28, !dbg !418
  %4 = load i32, ptr %first_seen, align 4, !dbg !418
  %first_seen4 = getelementptr inbounds nuw i8, ptr %b, i64 28, !dbg !419
  %5 = load i32, ptr %first_seen4, align 4, !dbg !419
  %sub5 = sub nsw i32 %4, %5, !dbg !420
  br label %return, !dbg !421

return:                                           ; preds = %if.end, %if.then
  %retval.0 = phi i32 [ %sub, %if.then ], [ %sub5, %if.end ], !dbg !405
  ret i32 %retval.0, !dbg !422
}

; Function Attrs: noinline nounwind uwtable
define internal void @print_bar(i32 noundef %count, i32 noundef %widest) #0 !dbg !423 {
entry:
    #dbg_value(i32 %count, !426, !DIExpression(), !427)
    #dbg_value(i32 %widest, !428, !DIExpression(), !427)
  %cmp = icmp sgt i32 %widest, 0, !dbg !429
  br i1 %cmp, label %cond.true, label %cond.false, !dbg !430

cond.true:                                        ; preds = %entry
  %mul = mul nsw i32 %count, 30, !dbg !431
  %div = sdiv i32 %mul, %widest, !dbg !432
  br label %cond.end, !dbg !430

cond.false:                                       ; preds = %entry
  br label %cond.end, !dbg !430

cond.end:                                         ; preds = %cond.false, %cond.true
  %cond = phi i32 [ %div, %cond.true ], [ 0, %cond.false ], !dbg !430
    #dbg_value(i32 %cond, !433, !DIExpression(), !427)
    #dbg_value(i32 0, !434, !DIExpression(), !436)
  br label %for.cond, !dbg !437

for.cond:                                         ; preds = %for.inc, %cond.end
  %i.0 = phi i32 [ 0, %cond.end ], [ %inc, %for.inc ], !dbg !438
    #dbg_value(i32 %i.0, !434, !DIExpression(), !436)
  %cmp1 = icmp slt i32 %i.0, %cond, !dbg !439
  br i1 %cmp1, label %for.body, label %for.end, !dbg !441

for.body:                                         ; preds = %for.cond
  %call = call i32 @putchar(i32 noundef 35) #7, !dbg !442
  br label %for.inc, !dbg !444

for.inc:                                          ; preds = %for.body
  %inc = add nuw nsw i32 %i.0, 1, !dbg !445
    #dbg_value(i32 %inc, !434, !DIExpression(), !436)
  br label %for.cond, !dbg !446, !llvm.loop !447

for.end:                                          ; preds = %for.cond
  %call2 = call i32 @putchar(i32 noundef 10) #7, !dbg !449
  ret void, !dbg !450
}

; Function Attrs: noinline nounwind uwtable
define internal ptr @longest(ptr noundef %entries, i32 noundef %n) #0 !dbg !451 {
entry:
    #dbg_value(ptr %entries, !454, !DIExpression(), !455)
    #dbg_value(i32 %n, !456, !DIExpression(), !455)
    #dbg_value(ptr null, !457, !DIExpression(), !455)
    #dbg_value(i64 0, !458, !DIExpression(), !455)
    #dbg_value(i32 0, !459, !DIExpression(), !461)
  br label %for.cond, !dbg !462

for.cond:                                         ; preds = %for.inc, %entry
  %best.0 = phi ptr [ null, %entry ], [ %best.1, %for.inc ], !dbg !455
  %best_length.0 = phi i64 [ 0, %entry ], [ %best_length.1, %for.inc ], !dbg !455
  %i.0 = phi i32 [ 0, %entry ], [ %inc, %for.inc ], !dbg !463
    #dbg_value(i32 %i.0, !459, !DIExpression(), !461)
    #dbg_value(i64 %best_length.0, !458, !DIExpression(), !455)
    #dbg_value(ptr %best.0, !457, !DIExpression(), !455)
  %cmp = icmp slt i32 %i.0, %n, !dbg !464
  br i1 %cmp, label %for.body, label %for.end, !dbg !466

for.body:                                         ; preds = %for.cond
  %idxprom = zext nneg i32 %i.0 to i64, !dbg !467
  %arrayidx = getelementptr inbounds nuw %struct.entry, ptr %entries, i64 %idxprom, !dbg !467
  %call = call i64 @strlen(ptr noundef nonnull dereferenceable(1) %arrayidx) #9, !dbg !469
    #dbg_value(i64 %call, !470, !DIExpression(), !471)
  %cmp1 = icmp ugt i64 %call, %best_length.0, !dbg !472
  br i1 %cmp1, label %if.then, label %if.end, !dbg !472

if.then:                                          ; preds = %for.body
  %idxprom2 = zext nneg i32 %i.0 to i64, !dbg !474
  %arrayidx3 = getelementptr inbounds nuw %struct.entry, ptr %entries, i64 %idxprom2, !dbg !474
    #dbg_value(ptr %arrayidx3, !457, !DIExpression(), !455)
    #dbg_value(i64 %call, !458, !DIExpression(), !455)
  br label %if.end, !dbg !476

if.end:                                           ; preds = %if.then, %for.body
  %best.1 = phi ptr [ %arrayidx3, %if.then ], [ %best.0, %for.body ], !dbg !455
  %best_length.1 = phi i64 [ %call, %if.then ], [ %best_length.0, %for.body ], !dbg !455
    #dbg_value(i64 %best_length.1, !458, !DIExpression(), !455)
    #dbg_value(ptr %best.1, !457, !DIExpression(), !455)
  br label %for.inc, !dbg !477

for.inc:                                          ; preds = %if.end
  %inc = add nuw nsw i32 %i.0, 1, !dbg !478
    #dbg_value(i32 %inc, !459, !DIExpression(), !461)
  br label %for.cond, !dbg !479, !llvm.loop !480

for.end:                                          ; preds = %for.cond
  ret ptr %best.0, !dbg !482
}

; Function Attrs: noinline nounwind uwtable
define internal double @mean_length(ptr noundef %entries, i32 noundef %n) #0 !dbg !483 {
entry:
    #dbg_value(ptr %entries, !486, !DIExpression(), !487)
    #dbg_value(i32 %n, !488, !DIExpression(), !487)
    #dbg_value(i64 0, !489, !DIExpression(), !487)
    #dbg_value(i64 0, !490, !DIExpression(), !487)
    #dbg_value(i32 0, !491, !DIExpression(), !493)
  br label %for.cond, !dbg !494

for.cond:                                         ; preds = %for.inc, %entry
  %letters.0 = phi i64 [ 0, %entry ], [ %add, %for.inc ], !dbg !487
  %words.0 = phi i64 [ 0, %entry ], [ %add7, %for.inc ], !dbg !487
  %i.0 = phi i32 [ 0, %entry ], [ %inc, %for.inc ], !dbg !495
    #dbg_value(i32 %i.0, !491, !DIExpression(), !493)
    #dbg_value(i64 %words.0, !490, !DIExpression(), !487)
    #dbg_value(i64 %letters.0, !489, !DIExpression(), !487)
  %cmp = icmp slt i32 %i.0, %n, !dbg !496
  br i1 %cmp, label %for.body, label %for.end, !dbg !498

for.body:                                         ; preds = %for.cond
    #dbg_value(!DIArgList(i64 poison, i64 poison, i32 poison), !489, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_LLVM_arg, 2, DW_OP_LLVM_convert, 32, DW_ATE_signed, DW_OP_LLVM_convert, 64, DW_ATE_signed, DW_OP_mul, DW_OP_plus, DW_OP_stack_value), !487)
    #dbg_value(!DIArgList(i64 poison, i32 poison), !490, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_LLVM_convert, 32, DW_ATE_signed, DW_OP_LLVM_convert, 64, DW_ATE_signed, DW_OP_plus, DW_OP_stack_value), !487)
  br label %for.inc, !dbg !499

for.inc:                                          ; preds = %for.body
  %idxprom3 = zext nneg i32 %i.0 to i64, !dbg !501
  %arrayidx4 = getelementptr inbounds nuw %struct.entry, ptr %entries, i64 %idxprom3, !dbg !501
  %count5 = getelementptr inbounds nuw i8, ptr %arrayidx4, i64 24, !dbg !502
  %0 = load i32, ptr %count5, align 4, !dbg !502
    #dbg_value(!DIArgList(i64 %words.0, i32 %0), !490, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_LLVM_convert, 32, DW_ATE_signed, DW_OP_LLVM_convert, 64, DW_ATE_signed, DW_OP_plus, DW_OP_stack_value), !487)
  %conv6 = sext i32 %0 to i64, !dbg !501
    #dbg_value(!DIArgList(i64 %words.0, i64 %conv6), !490, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_plus, DW_OP_stack_value), !487)
  %add7 = add nsw i64 %words.0, %conv6, !dbg !503
    #dbg_value(i64 %add7, !490, !DIExpression(), !487)
  %idxprom = zext nneg i32 %i.0 to i64, !dbg !504
  %arrayidx = getelementptr inbounds nuw %struct.entry, ptr %entries, i64 %idxprom, !dbg !504
  %call = call i64 @strlen(ptr noundef nonnull dereferenceable(1) %arrayidx) #9, !dbg !505
  %idxprom1 = zext nneg i32 %i.0 to i64, !dbg !506
  %arrayidx2 = getelementptr inbounds nuw %struct.entry, ptr %entries, i64 %idxprom1, !dbg !506
  %count = getelementptr inbounds nuw i8, ptr %arrayidx2, i64 24, !dbg !507
  %1 = load i32, ptr %count, align 4, !dbg !507
    #dbg_value(!DIArgList(i64 %letters.0, i64 %call, i32 %1), !489, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_LLVM_arg, 2, DW_OP_LLVM_convert, 32, DW_ATE_signed, DW_OP_LLVM_convert, 64, DW_ATE_signed, DW_OP_mul, DW_OP_plus, DW_OP_stack_value), !487)
  %conv = sext i32 %1 to i64, !dbg !506
    #dbg_value(!DIArgList(i64 %letters.0, i64 %call, i64 %conv), !489, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_LLVM_arg, 2, DW_OP_mul, DW_OP_plus, DW_OP_stack_value), !487)
  %mul = mul nsw i64 %call, %conv, !dbg !508
    #dbg_value(!DIArgList(i64 %letters.0, i64 %mul), !489, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_plus, DW_OP_stack_value), !487)
  %add = add nsw i64 %letters.0, %mul, !dbg !509
    #dbg_value(i64 %add, !489, !DIExpression(), !487)
  %inc = add nuw nsw i32 %i.0, 1, !dbg !510
    #dbg_value(i32 %inc, !491, !DIExpression(), !493)
  br label %for.cond, !dbg !511, !llvm.loop !512

for.end:                                          ; preds = %for.cond
  %cmp8 = icmp sgt i64 %words.0, 0, !dbg !514
  br i1 %cmp8, label %cond.true, label %cond.false, !dbg !515

cond.true:                                        ; preds = %for.end
  %conv10 = sitofp i64 %letters.0 to double, !dbg !516
  %conv11 = sitofp i64 %words.0 to double, !dbg !517
  %div = fdiv double %conv10, %conv11, !dbg !518
  br label %cond.end, !dbg !515

cond.false:                                       ; preds = %for.end
  br label %cond.end, !dbg !515

cond.end:                                         ; preds = %cond.false, %cond.true
  %cond = phi double [ %div, %cond.true ], [ 0.000000e+00, %cond.false ], !dbg !515
  ret double %cond, !dbg !519
}

; Function Attrs: noinline nounwind uwtable
define internal i32 @singletons(ptr noundef %entries, i32 noundef %n) #0 !dbg !520 {
entry:
    #dbg_value(ptr %entries, !523, !DIExpression(), !524)
    #dbg_value(i32 %n, !525, !DIExpression(), !524)
    #dbg_value(i32 0, !526, !DIExpression(), !524)
    #dbg_value(i32 %n, !527, !DIExpression(DW_OP_constu, 1, DW_OP_minus, DW_OP_stack_value), !529)
  br label %for.cond, !dbg !530

for.cond:                                         ; preds = %for.inc, %entry
  %count.0 = phi i32 [ 0, %entry ], [ %inc, %for.inc ], !dbg !524
  %i.0.in = phi i32 [ %n, %entry ], [ %i.0, %for.inc ]
  %i.0 = add nsw i32 %i.0.in, -1, !dbg !531
    #dbg_value(i32 %i.0, !527, !DIExpression(), !529)
    #dbg_value(i32 %count.0, !526, !DIExpression(), !524)
  %cmp = icmp sgt i32 %i.0.in, 0, !dbg !532
  br i1 %cmp, label %land.rhs, label %land.end, !dbg !534

land.rhs:                                         ; preds = %for.cond
  %idxprom = sext i32 %i.0 to i64, !dbg !535
  %arrayidx = getelementptr inbounds %struct.entry, ptr %entries, i64 %idxprom, !dbg !535
  %count1 = getelementptr inbounds nuw i8, ptr %arrayidx, i64 24, !dbg !536
  %0 = load i32, ptr %count1, align 4, !dbg !536
  %cmp2 = icmp eq i32 %0, 1, !dbg !537
  br label %land.end

land.end:                                         ; preds = %land.rhs, %for.cond
  %1 = phi i1 [ false, %for.cond ], [ %cmp2, %land.rhs ], !dbg !538
  br i1 %1, label %for.body, label %for.end, !dbg !539

for.body:                                         ; preds = %land.end
    #dbg_value(i32 %count.0, !526, !DIExpression(DW_OP_plus_uconst, 1, DW_OP_stack_value), !524)
  br label %for.inc, !dbg !540

for.inc:                                          ; preds = %for.body
  %inc = add nuw nsw i32 %count.0, 1, !dbg !542
    #dbg_value(i32 %inc, !526, !DIExpression(), !524)
    #dbg_value(i32 %i.0, !527, !DIExpression(DW_OP_constu, 1, DW_OP_minus, DW_OP_stack_value), !529)
  br label %for.cond, !dbg !543, !llvm.loop !544

for.end:                                          ; preds = %land.end
  ret i32 %count.0, !dbg !546
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
attributes #8 = { cold nounwind }
attributes #9 = { nounwind willreturn memory(read) }
attributes #10 = { nounwind willreturn memory(none) }

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
!140 = !DILocalVariable(name: "word", scope: !134, file: !3, line: 98, type: !43)
!141 = !DILocation(line: 98, column: 10, scope: !134)
!142 = !DILocalVariable(name: "position", scope: !134, file: !3, line: 99, type: !6)
!143 = !DILocation(line: 100, column: 5, scope: !134)
!144 = !DILocation(line: 100, column: 12, scope: !134)
!145 = !DILocation(line: 100, column: 35, scope: !134)
!146 = !DILocation(line: 101, column: 13, scope: !147)
!147 = distinct !DILexicalBlock(scope: !148, file: !3, line: 101, column: 13)
!148 = distinct !DILexicalBlock(scope: !134, file: !3, line: 100, column: 40)
!149 = !DILocation(line: 101, column: 46, scope: !147)
!150 = !DILocation(line: 102, column: 21, scope: !151)
!151 = distinct !DILexicalBlock(scope: !147, file: !3, line: 101, column: 51)
!152 = !DILocation(line: 102, column: 13, scope: !151)
!153 = !DILocation(line: 103, column: 13, scope: !151)
!154 = !DILocation(line: 105, column: 17, scope: !148)
!155 = distinct !{!155, !143, !156, !157}
!156 = !DILocation(line: 106, column: 5, scope: !134)
!157 = !{!"llvm.loop.mustprogress"}
!158 = !DILocation(line: 107, column: 5, scope: !134)
!159 = distinct !DISubprogram(name: "collect", scope: !3, file: !3, line: 120, type: !160, scopeLine: 120, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!160 = !DISubroutineType(types: !161)
!161 = !{!6, !162, !164}
!162 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !163, size: 64)
!163 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !96)
!164 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !40, size: 64)
!165 = !DILocalVariable(name: "table", arg: 1, scope: !159, file: !3, line: 120, type: !162)
!166 = !DILocation(line: 0, scope: !159)
!167 = !DILocalVariable(name: "out", arg: 2, scope: !159, file: !3, line: 120, type: !164)
!168 = !DILocalVariable(name: "n", scope: !159, file: !3, line: 121, type: !6)
!169 = !DILocalVariable(name: "i", scope: !170, file: !3, line: 122, type: !6)
!170 = distinct !DILexicalBlock(scope: !159, file: !3, line: 122, column: 5)
!171 = !DILocation(line: 0, scope: !170)
!172 = !DILocation(line: 122, column: 10, scope: !170)
!173 = !DILocation(line: 122, scope: !170)
!174 = !DILocation(line: 122, column: 23, scope: !175)
!175 = distinct !DILexicalBlock(scope: !170, file: !3, line: 122, column: 5)
!176 = !DILocation(line: 122, column: 5, scope: !170)
!177 = !DILocation(line: 123, column: 13, scope: !178)
!178 = distinct !DILexicalBlock(scope: !179, file: !3, line: 123, column: 13)
!179 = distinct !DILexicalBlock(scope: !175, file: !3, line: 122, column: 42)
!180 = !DILocation(line: 123, column: 29, scope: !178)
!181 = !DILocation(line: 123, column: 35, scope: !178)
!182 = !DILocation(line: 124, column: 18, scope: !183)
!183 = distinct !DILexicalBlock(scope: !178, file: !3, line: 123, column: 40)
!184 = !DILocation(line: 124, column: 13, scope: !183)
!185 = !DILocation(line: 124, column: 24, scope: !183)
!186 = !DILocation(line: 125, column: 9, scope: !183)
!187 = !DILocation(line: 126, column: 5, scope: !179)
!188 = !DILocation(line: 122, column: 38, scope: !175)
!189 = !DILocation(line: 122, column: 5, scope: !175)
!190 = distinct !{!190, !176, !191, !157}
!191 = !DILocation(line: 126, column: 5, scope: !170)
!192 = !DILocation(line: 127, column: 16, scope: !159)
!193 = !DILocation(line: 127, column: 5, scope: !159)
!194 = !DILocation(line: 128, column: 5, scope: !159)
!195 = distinct !DISubprogram(name: "report", scope: !3, file: !3, line: 170, type: !196, scopeLine: 170, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!196 = !DISubroutineType(types: !197)
!197 = !{null, !198, !6, !6}
!198 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !199, size: 64)
!199 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !40)
!200 = !DILocalVariable(name: "entries", arg: 1, scope: !195, file: !3, line: 170, type: !198)
!201 = !DILocation(line: 0, scope: !195)
!202 = !DILocalVariable(name: "n", arg: 2, scope: !195, file: !3, line: 170, type: !6)
!203 = !DILocalVariable(name: "total", arg: 3, scope: !195, file: !3, line: 170, type: !6)
!204 = !DILocation(line: 171, column: 19, scope: !195)
!205 = !DILocation(line: 171, column: 17, scope: !195)
!206 = !DILocalVariable(name: "shown", scope: !195, file: !3, line: 171, type: !6)
!207 = !DILocation(line: 172, column: 5, scope: !195)
!208 = !DILocalVariable(name: "i", scope: !209, file: !3, line: 173, type: !6)
!209 = distinct !DILexicalBlock(scope: !195, file: !3, line: 173, column: 5)
!210 = !DILocation(line: 0, scope: !209)
!211 = !DILocation(line: 173, column: 10, scope: !209)
!212 = !DILocation(line: 173, scope: !209)
!213 = !DILocation(line: 173, column: 23, scope: !214)
!214 = distinct !DILexicalBlock(scope: !209, file: !3, line: 173, column: 5)
!215 = !DILocation(line: 173, column: 5, scope: !209)
!216 = !DILocation(line: 174, column: 30, scope: !217)
!217 = distinct !DILexicalBlock(scope: !214, file: !3, line: 173, column: 37)
!218 = !DILocation(line: 174, column: 47, scope: !217)
!219 = !DILocation(line: 174, column: 58, scope: !217)
!220 = !DILocation(line: 174, column: 9, scope: !217)
!221 = !DILocation(line: 175, column: 19, scope: !217)
!222 = !DILocation(line: 175, column: 30, scope: !217)
!223 = !DILocation(line: 175, column: 48, scope: !217)
!224 = !DILocation(line: 175, column: 9, scope: !217)
!225 = !DILocation(line: 176, column: 5, scope: !217)
!226 = !DILocation(line: 173, column: 33, scope: !214)
!227 = !DILocation(line: 173, column: 5, scope: !214)
!228 = distinct !{!228, !215, !229, !157}
!229 = !DILocation(line: 176, column: 5, scope: !209)
!230 = !DILocation(line: 177, column: 32, scope: !195)
!231 = !DILocalVariable(name: "word", scope: !195, file: !3, line: 177, type: !198)
!232 = !DILocation(line: 178, column: 14, scope: !233)
!233 = distinct !DILexicalBlock(scope: !195, file: !3, line: 178, column: 9)
!234 = !DILocation(line: 179, column: 9, scope: !235)
!235 = distinct !DILexicalBlock(scope: !233, file: !3, line: 178, column: 23)
!236 = !DILocation(line: 180, column: 5, scope: !235)
!237 = !DILocation(line: 181, column: 43, scope: !195)
!238 = !DILocation(line: 181, column: 5, scope: !195)
!239 = !DILocation(line: 182, column: 37, scope: !195)
!240 = !DILocation(line: 182, column: 5, scope: !195)
!241 = !DILocation(line: 183, column: 1, scope: !195)
!242 = distinct !DISubprogram(name: "table_lookup", scope: !3, file: !3, line: 64, type: !243, scopeLine: 64, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!243 = !DISubroutineType(types: !244)
!244 = !{!6, !162, !74}
!245 = !DILocalVariable(name: "table", arg: 1, scope: !242, file: !3, line: 64, type: !162)
!246 = !DILocation(line: 0, scope: !242)
!247 = !DILocalVariable(name: "word", arg: 2, scope: !242, file: !3, line: 64, type: !74)
!248 = !DILocation(line: 65, column: 26, scope: !242)
!249 = !DILocalVariable(name: "index", scope: !242, file: !3, line: 65, type: !12)
!250 = !DILocalVariable(name: "probe", scope: !251, file: !3, line: 66, type: !6)
!251 = distinct !DILexicalBlock(scope: !242, file: !3, line: 66, column: 5)
!252 = !DILocation(line: 0, scope: !251)
!253 = !DILocation(line: 66, column: 10, scope: !251)
!254 = !DILocation(line: 66, scope: !251)
!255 = !DILocation(line: 66, column: 31, scope: !256)
!256 = distinct !DILexicalBlock(scope: !251, file: !3, line: 66, column: 5)
!257 = !DILocation(line: 66, column: 5, scope: !251)
!258 = !DILocation(line: 67, column: 37, scope: !259)
!259 = distinct !DILexicalBlock(scope: !256, file: !3, line: 66, column: 54)
!260 = !DILocalVariable(name: "slot", scope: !259, file: !3, line: 67, type: !198)
!261 = !DILocation(line: 0, scope: !259)
!262 = !DILocation(line: 68, column: 19, scope: !263)
!263 = distinct !DILexicalBlock(scope: !259, file: !3, line: 68, column: 13)
!264 = !DILocation(line: 68, column: 25, scope: !263)
!265 = !DILocation(line: 69, column: 13, scope: !266)
!266 = distinct !DILexicalBlock(scope: !263, file: !3, line: 68, column: 31)
!267 = !DILocation(line: 71, column: 13, scope: !268)
!268 = distinct !DILexicalBlock(scope: !259, file: !3, line: 71, column: 13)
!269 = !DILocation(line: 71, column: 38, scope: !268)
!270 = !DILocation(line: 72, column: 26, scope: !271)
!271 = distinct !DILexicalBlock(scope: !268, file: !3, line: 71, column: 44)
!272 = !DILocation(line: 72, column: 13, scope: !271)
!273 = !DILocation(line: 75, column: 5, scope: !259)
!274 = !DILocation(line: 74, column: 24, scope: !259)
!275 = !DILocation(line: 66, column: 50, scope: !256)
!276 = !DILocation(line: 66, column: 5, scope: !256)
!277 = distinct !{!277, !257, !278, !157}
!278 = !DILocation(line: 75, column: 5, scope: !251)
!279 = !DILocation(line: 76, column: 5, scope: !242)
!280 = !DILocation(line: 77, column: 1, scope: !242)
!281 = distinct !DISubprogram(name: "next_word", scope: !3, file: !3, line: 80, type: !282, scopeLine: 80, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!282 = !DISubroutineType(types: !283)
!283 = !{!6, !284, !285}
!284 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !74, size: 64)
!285 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !29, size: 64)
!286 = !DILocalVariable(name: "text", arg: 1, scope: !281, file: !3, line: 80, type: !284)
!287 = !DILocation(line: 0, scope: !281)
!288 = !DILocalVariable(name: "word", arg: 2, scope: !281, file: !3, line: 80, type: !285)
!289 = !DILocation(line: 81, column: 21, scope: !281)
!290 = !DILocalVariable(name: "p", scope: !281, file: !3, line: 81, type: !74)
!291 = !DILocation(line: 82, column: 5, scope: !281)
!292 = !DILocation(line: 82, column: 12, scope: !281)
!293 = !DILocation(line: 82, column: 15, scope: !281)
!294 = !DILocation(line: 82, column: 23, scope: !281)
!295 = !DILocation(line: 82, column: 27, scope: !281)
!296 = !DILocation(line: 82, column: 50, scope: !281)
!297 = !DILocation(line: 82, column: 26, scope: !281)
!298 = !DILocation(line: 83, column: 10, scope: !299)
!299 = distinct !DILexicalBlock(scope: !281, file: !3, line: 82, column: 55)
!300 = distinct !{!300, !291, !301, !157}
!301 = !DILocation(line: 84, column: 5, scope: !281)
!302 = !DILocalVariable(name: "length", scope: !281, file: !3, line: 85, type: !6)
!303 = !DILocation(line: 86, column: 5, scope: !281)
!304 = !DILocation(line: 86, column: 12, scope: !281)
!305 = !DILocation(line: 86, column: 35, scope: !281)
!306 = !DILocation(line: 87, column: 20, scope: !307)
!307 = distinct !DILexicalBlock(scope: !308, file: !3, line: 87, column: 13)
!308 = distinct !DILexicalBlock(scope: !281, file: !3, line: 86, column: 40)
!309 = !DILocation(line: 88, column: 59, scope: !310)
!310 = distinct !DILexicalBlock(scope: !307, file: !3, line: 87, column: 36)
!311 = !DILocation(line: 88, column: 44, scope: !310)
!312 = !DILocation(line: 88, column: 36, scope: !310)
!313 = !DILocation(line: 88, column: 30, scope: !310)
!314 = !DILocation(line: 88, column: 24, scope: !310)
!315 = !DILocation(line: 88, column: 13, scope: !310)
!316 = !DILocation(line: 88, column: 28, scope: !310)
!317 = !DILocation(line: 89, column: 9, scope: !310)
!318 = !DILocation(line: 90, column: 10, scope: !308)
!319 = distinct !{!319, !303, !320, !157}
!320 = !DILocation(line: 91, column: 5, scope: !281)
!321 = !DILocation(line: 92, column: 5, scope: !281)
!322 = !DILocation(line: 92, column: 18, scope: !281)
!323 = !DILocation(line: 93, column: 11, scope: !281)
!324 = !DILocation(line: 94, column: 5, scope: !281)
!325 = distinct !DISubprogram(name: "table_add", scope: !3, file: !3, line: 44, type: !326, scopeLine: 44, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!326 = !DISubroutineType(types: !327)
!327 = !{!6, !129, !74, !6}
!328 = !DILocalVariable(name: "table", arg: 1, scope: !325, file: !3, line: 44, type: !129)
!329 = !DILocation(line: 0, scope: !325)
!330 = !DILocalVariable(name: "word", arg: 2, scope: !325, file: !3, line: 44, type: !74)
!331 = !DILocalVariable(name: "position", arg: 3, scope: !325, file: !3, line: 44, type: !6)
!332 = !DILocation(line: 45, column: 26, scope: !325)
!333 = !DILocalVariable(name: "index", scope: !325, file: !3, line: 45, type: !12)
!334 = !DILocalVariable(name: "probe", scope: !335, file: !3, line: 46, type: !6)
!335 = distinct !DILexicalBlock(scope: !325, file: !3, line: 46, column: 5)
!336 = !DILocation(line: 0, scope: !335)
!337 = !DILocation(line: 46, column: 10, scope: !335)
!338 = !DILocation(line: 46, scope: !335)
!339 = !DILocation(line: 46, column: 31, scope: !340)
!340 = distinct !DILexicalBlock(scope: !335, file: !3, line: 46, column: 5)
!341 = !DILocation(line: 46, column: 5, scope: !335)
!342 = !DILocation(line: 47, column: 31, scope: !343)
!343 = distinct !DILexicalBlock(scope: !340, file: !3, line: 46, column: 54)
!344 = !DILocalVariable(name: "slot", scope: !343, file: !3, line: 47, type: !164)
!345 = !DILocation(line: 0, scope: !343)
!346 = !DILocation(line: 48, column: 19, scope: !347)
!347 = distinct !DILexicalBlock(scope: !343, file: !3, line: 48, column: 13)
!348 = !DILocation(line: 48, column: 25, scope: !347)
!349 = !DILocation(line: 49, column: 13, scope: !350)
!350 = distinct !DILexicalBlock(scope: !347, file: !3, line: 48, column: 31)
!351 = !DILocation(line: 50, column: 19, scope: !350)
!352 = !DILocation(line: 50, column: 25, scope: !350)
!353 = !DILocation(line: 51, column: 19, scope: !350)
!354 = !DILocation(line: 51, column: 30, scope: !350)
!355 = !DILocation(line: 52, column: 20, scope: !350)
!356 = !DILocation(line: 52, column: 24, scope: !350)
!357 = !DILocation(line: 53, column: 13, scope: !350)
!358 = !DILocation(line: 55, column: 13, scope: !359)
!359 = distinct !DILexicalBlock(scope: !343, file: !3, line: 55, column: 13)
!360 = !DILocation(line: 55, column: 38, scope: !359)
!361 = !DILocation(line: 56, column: 19, scope: !362)
!362 = distinct !DILexicalBlock(scope: !359, file: !3, line: 55, column: 44)
!363 = !DILocation(line: 56, column: 24, scope: !362)
!364 = !DILocation(line: 57, column: 13, scope: !362)
!365 = !DILocation(line: 60, column: 5, scope: !343)
!366 = !DILocation(line: 59, column: 24, scope: !343)
!367 = !DILocation(line: 46, column: 50, scope: !340)
!368 = !DILocation(line: 46, column: 5, scope: !340)
!369 = distinct !{!369, !341, !370, !157}
!370 = !DILocation(line: 60, column: 5, scope: !335)
!371 = !DILocation(line: 61, column: 5, scope: !325)
!372 = !DILocation(line: 62, column: 1, scope: !325)
!373 = distinct !DISubprogram(name: "hash_word", scope: !3, file: !3, line: 30, type: !374, scopeLine: 30, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!374 = !DISubroutineType(types: !375)
!375 = !{!12, !74}
!376 = !DILocalVariable(name: "word", arg: 1, scope: !373, file: !3, line: 30, type: !74)
!377 = !DILocation(line: 0, scope: !373)
!378 = !DILocalVariable(name: "hash", scope: !373, file: !3, line: 31, type: !12)
!379 = !DILocalVariable(name: "p", scope: !380, file: !3, line: 32, type: !74)
!380 = distinct !DILexicalBlock(scope: !373, file: !3, line: 32, column: 5)
!381 = !DILocation(line: 0, scope: !380)
!382 = !DILocation(line: 32, column: 10, scope: !380)
!383 = !DILocation(line: 32, scope: !380)
!384 = !DILocation(line: 32, column: 32, scope: !385)
!385 = distinct !DILexicalBlock(scope: !380, file: !3, line: 32, column: 5)
!386 = !DILocation(line: 32, column: 35, scope: !385)
!387 = !DILocation(line: 32, column: 5, scope: !380)
!388 = !DILocation(line: 35, column: 5, scope: !389)
!389 = distinct !DILexicalBlock(scope: !385, file: !3, line: 32, column: 49)
!390 = !DILocation(line: 33, column: 32, scope: !389)
!391 = !DILocation(line: 33, column: 17, scope: !389)
!392 = !DILocation(line: 33, column: 14, scope: !389)
!393 = !DILocation(line: 34, column: 14, scope: !389)
!394 = !DILocation(line: 32, column: 45, scope: !385)
!395 = !DILocation(line: 32, column: 5, scope: !385)
!396 = distinct !{!396, !387, !397, !157}
!397 = !DILocation(line: 35, column: 5, scope: !380)
!398 = !DILocation(line: 36, column: 5, scope: !373)
!399 = distinct !DISubprogram(name: "by_count", scope: !3, file: !3, line: 111, type: !400, scopeLine: 111, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!400 = !DISubroutineType(types: !401)
!401 = !{!6, !402, !402}
!402 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !403, size: 64)
!403 = !DIDerivedType(tag: DW_TAG_const_type, baseType: null)
!404 = !DILocalVariable(name: "a", arg: 1, scope: !399, file: !3, line: 111, type: !402)
!405 = !DILocation(line: 0, scope: !399)
!406 = !DILocalVariable(name: "b", arg: 2, scope: !399, file: !3, line: 111, type: !402)
!407 = !DILocalVariable(name: "x", scope: !399, file: !3, line: 112, type: !198)
!408 = !DILocalVariable(name: "y", scope: !399, file: !3, line: 113, type: !198)
!409 = !DILocation(line: 114, column: 12, scope: !410)
!410 = distinct !DILexicalBlock(scope: !399, file: !3, line: 114, column: 9)
!411 = !DILocation(line: 114, column: 24, scope: !410)
!412 = !DILocation(line: 114, column: 18, scope: !410)
!413 = !DILocation(line: 115, column: 19, scope: !414)
!414 = distinct !DILexicalBlock(scope: !410, file: !3, line: 114, column: 31)
!415 = !DILocation(line: 115, column: 30, scope: !414)
!416 = !DILocation(line: 115, column: 25, scope: !414)
!417 = !DILocation(line: 115, column: 9, scope: !414)
!418 = !DILocation(line: 117, column: 15, scope: !399)
!419 = !DILocation(line: 117, column: 31, scope: !399)
!420 = !DILocation(line: 117, column: 26, scope: !399)
!421 = !DILocation(line: 117, column: 5, scope: !399)
!422 = !DILocation(line: 118, column: 1, scope: !399)
!423 = distinct !DISubprogram(name: "print_bar", scope: !3, file: !3, line: 162, type: !424, scopeLine: 162, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!424 = !DISubroutineType(types: !425)
!425 = !{null, !6, !6}
!426 = !DILocalVariable(name: "count", arg: 1, scope: !423, file: !3, line: 162, type: !6)
!427 = !DILocation(line: 0, scope: !423)
!428 = !DILocalVariable(name: "widest", arg: 2, scope: !423, file: !3, line: 162, type: !6)
!429 = !DILocation(line: 163, column: 24, scope: !423)
!430 = !DILocation(line: 163, column: 17, scope: !423)
!431 = !DILocation(line: 163, column: 36, scope: !423)
!432 = !DILocation(line: 163, column: 41, scope: !423)
!433 = !DILocalVariable(name: "width", scope: !423, file: !3, line: 163, type: !6)
!434 = !DILocalVariable(name: "i", scope: !435, file: !3, line: 164, type: !6)
!435 = distinct !DILexicalBlock(scope: !423, file: !3, line: 164, column: 5)
!436 = !DILocation(line: 0, scope: !435)
!437 = !DILocation(line: 164, column: 10, scope: !435)
!438 = !DILocation(line: 164, scope: !435)
!439 = !DILocation(line: 164, column: 23, scope: !440)
!440 = distinct !DILexicalBlock(scope: !435, file: !3, line: 164, column: 5)
!441 = !DILocation(line: 164, column: 5, scope: !435)
!442 = !DILocation(line: 165, column: 9, scope: !443)
!443 = distinct !DILexicalBlock(scope: !440, file: !3, line: 164, column: 37)
!444 = !DILocation(line: 166, column: 5, scope: !443)
!445 = !DILocation(line: 164, column: 33, scope: !440)
!446 = !DILocation(line: 164, column: 5, scope: !440)
!447 = distinct !{!447, !441, !448, !157}
!448 = !DILocation(line: 166, column: 5, scope: !435)
!449 = !DILocation(line: 167, column: 5, scope: !423)
!450 = !DILocation(line: 168, column: 1, scope: !423)
!451 = distinct !DISubprogram(name: "longest", scope: !3, file: !3, line: 141, type: !452, scopeLine: 141, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!452 = !DISubroutineType(types: !453)
!453 = !{!198, !198, !6}
!454 = !DILocalVariable(name: "entries", arg: 1, scope: !451, file: !3, line: 141, type: !198)
!455 = !DILocation(line: 0, scope: !451)
!456 = !DILocalVariable(name: "n", arg: 2, scope: !451, file: !3, line: 141, type: !6)
!457 = !DILocalVariable(name: "best", scope: !451, file: !3, line: 142, type: !198)
!458 = !DILocalVariable(name: "best_length", scope: !451, file: !3, line: 143, type: !30)
!459 = !DILocalVariable(name: "i", scope: !460, file: !3, line: 144, type: !6)
!460 = distinct !DILexicalBlock(scope: !451, file: !3, line: 144, column: 5)
!461 = !DILocation(line: 0, scope: !460)
!462 = !DILocation(line: 144, column: 10, scope: !460)
!463 = !DILocation(line: 144, scope: !460)
!464 = !DILocation(line: 144, column: 23, scope: !465)
!465 = distinct !DILexicalBlock(scope: !460, file: !3, line: 144, column: 5)
!466 = !DILocation(line: 144, column: 5, scope: !460)
!467 = !DILocation(line: 145, column: 32, scope: !468)
!468 = distinct !DILexicalBlock(scope: !465, file: !3, line: 144, column: 33)
!469 = !DILocation(line: 145, column: 25, scope: !468)
!470 = !DILocalVariable(name: "length", scope: !468, file: !3, line: 145, type: !30)
!471 = !DILocation(line: 0, scope: !468)
!472 = !DILocation(line: 146, column: 20, scope: !473)
!473 = distinct !DILexicalBlock(scope: !468, file: !3, line: 146, column: 13)
!474 = !DILocation(line: 147, column: 21, scope: !475)
!475 = distinct !DILexicalBlock(scope: !473, file: !3, line: 146, column: 35)
!476 = !DILocation(line: 149, column: 9, scope: !475)
!477 = !DILocation(line: 150, column: 5, scope: !468)
!478 = !DILocation(line: 144, column: 29, scope: !465)
!479 = !DILocation(line: 144, column: 5, scope: !465)
!480 = distinct !{!480, !466, !481, !157}
!481 = !DILocation(line: 150, column: 5, scope: !460)
!482 = !DILocation(line: 151, column: 5, scope: !451)
!483 = distinct !DISubprogram(name: "mean_length", scope: !3, file: !3, line: 131, type: !484, scopeLine: 131, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!484 = !DISubroutineType(types: !485)
!485 = !{!35, !198, !6}
!486 = !DILocalVariable(name: "entries", arg: 1, scope: !483, file: !3, line: 131, type: !198)
!487 = !DILocation(line: 0, scope: !483)
!488 = !DILocalVariable(name: "n", arg: 2, scope: !483, file: !3, line: 131, type: !6)
!489 = !DILocalVariable(name: "letters", scope: !483, file: !3, line: 132, type: !34)
!490 = !DILocalVariable(name: "words", scope: !483, file: !3, line: 133, type: !34)
!491 = !DILocalVariable(name: "i", scope: !492, file: !3, line: 134, type: !6)
!492 = distinct !DILexicalBlock(scope: !483, file: !3, line: 134, column: 5)
!493 = !DILocation(line: 0, scope: !492)
!494 = !DILocation(line: 134, column: 10, scope: !492)
!495 = !DILocation(line: 134, scope: !492)
!496 = !DILocation(line: 134, column: 23, scope: !497)
!497 = distinct !DILexicalBlock(scope: !492, file: !3, line: 134, column: 5)
!498 = !DILocation(line: 134, column: 5, scope: !492)
!499 = !DILocation(line: 137, column: 5, scope: !500)
!500 = distinct !DILexicalBlock(scope: !497, file: !3, line: 134, column: 33)
!501 = !DILocation(line: 136, column: 18, scope: !500)
!502 = !DILocation(line: 136, column: 29, scope: !500)
!503 = !DILocation(line: 136, column: 15, scope: !500)
!504 = !DILocation(line: 135, column: 33, scope: !500)
!505 = !DILocation(line: 135, column: 26, scope: !500)
!506 = !DILocation(line: 135, column: 52, scope: !500)
!507 = !DILocation(line: 135, column: 63, scope: !500)
!508 = !DILocation(line: 135, column: 50, scope: !500)
!509 = !DILocation(line: 135, column: 17, scope: !500)
!510 = !DILocation(line: 134, column: 29, scope: !497)
!511 = !DILocation(line: 134, column: 5, scope: !497)
!512 = distinct !{!512, !498, !513, !157}
!513 = !DILocation(line: 137, column: 5, scope: !492)
!514 = !DILocation(line: 138, column: 18, scope: !483)
!515 = !DILocation(line: 138, column: 12, scope: !483)
!516 = !DILocation(line: 138, column: 24, scope: !483)
!517 = !DILocation(line: 138, column: 42, scope: !483)
!518 = !DILocation(line: 138, column: 40, scope: !483)
!519 = !DILocation(line: 138, column: 5, scope: !483)
!520 = distinct !DISubprogram(name: "singletons", scope: !3, file: !3, line: 154, type: !521, scopeLine: 154, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!521 = !DISubroutineType(types: !522)
!522 = !{!6, !198, !6}
!523 = !DILocalVariable(name: "entries", arg: 1, scope: !520, file: !3, line: 154, type: !198)
!524 = !DILocation(line: 0, scope: !520)
!525 = !DILocalVariable(name: "n", arg: 2, scope: !520, file: !3, line: 154, type: !6)
!526 = !DILocalVariable(name: "count", scope: !520, file: !3, line: 155, type: !6)
!527 = !DILocalVariable(name: "i", scope: !528, file: !3, line: 156, type: !6)
!528 = distinct !DILexicalBlock(scope: !520, file: !3, line: 156, column: 5)
!529 = !DILocation(line: 0, scope: !528)
!530 = !DILocation(line: 156, column: 10, scope: !528)
!531 = !DILocation(line: 156, scope: !528)
!532 = !DILocation(line: 156, column: 27, scope: !533)
!533 = distinct !DILexicalBlock(scope: !528, file: !3, line: 156, column: 5)
!534 = !DILocation(line: 156, column: 32, scope: !533)
!535 = !DILocation(line: 156, column: 35, scope: !533)
!536 = !DILocation(line: 156, column: 46, scope: !533)
!537 = !DILocation(line: 156, column: 52, scope: !533)
!538 = !DILocation(line: 0, scope: !533)
!539 = !DILocation(line: 156, column: 5, scope: !528)
!540 = !DILocation(line: 158, column: 5, scope: !541)
!541 = distinct !DILexicalBlock(scope: !533, file: !3, line: 156, column: 63)
!542 = !DILocation(line: 157, column: 14, scope: !541)
!543 = !DILocation(line: 156, column: 5, scope: !533)
!544 = distinct !{!544, !539, !545, !157}
!545 = !DILocation(line: 158, column: 5, scope: !528)
!546 = !DILocation(line: 159, column: 5, scope: !520)
