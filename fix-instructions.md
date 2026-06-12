# OLI POS — Bug Fix Instructions

Fix the following bugs in `pos.html` (same directory as this file).

---

## Bug 1: Discount % mode doesn't calculate correctly

**Function:** `getCartTotals()` (around line 1478)

The `discountMode` variable is set by `toggleDiscountMode()` but never used in `getCartTotals()`. The discount is always treated as a fixed ₱ amount.

**Fix:** Replace `getCartTotals()` with:

```js
function getCartTotals(){
  const subtotal=Object.keys(cart).reduce((s,id)=>{
    const p=products.find(x=>x.id==id);return s+(p?p.price*cart[id]:0);
  },0);
  const raw=parseFloat(document.getElementById('discountInput').value)||0;
  const discAmt=Math.min(
    discountMode==='pct' ? subtotal*(raw/100) : raw,
    subtotal
  );
  const discLabel=document.getElementById('discountLabel')?.value.trim()||'Discount';
  return{subtotal,discAmt,discLabel,tax:0,taxAmt:0,disc:0,total:subtotal-discAmt};
}
```

---

## Bug 2: Stock never syncs to Supabase after a sale

**Function:** `confirmSale()` (around line 1530)

`clearCart()` is called before `saveProducts()`, so by the time `saveProducts()` loops over `Object.keys(cart)`, the cart is empty and no stock updates are sent to Supabase.

**Fix:** In `confirmSale()`, replace:
```js
closeCheckout();
const prevCart={...cart};
clearCart();
renderProducts();
await saveSaleToDb(sale);
saveProducts();
showReceipt(sale);
```

With:
```js
closeCheckout();
const soldCart={...cart};
clearCart();
renderProducts();
await saveSaleToDb(sale);
saveProducts(soldCart);
showReceipt(sale);
```

And update `saveProducts()` to accept the cart snapshot:
```js
function saveProducts(soldCart){
  localStorage.setItem('oli_products_cache',JSON.stringify(products));
  Object.keys(soldCart||{}).forEach(id=>{
    const p=products.find(x=>x.id==id);
    if(p)sb.from('products').update({stock:p.stock}).eq('id',p.id).then(()=>{});
  });
}
```

---

## Bug 3: Offline queue loses sales if a sync insert fails

**Function:** `syncOfflineQueue()` (around line 1205)

The queue is cleared before inserts complete. If any insert fails, that sale is lost permanently.

**Fix:** Replace `syncOfflineQueue()` with:
```js
async function syncOfflineQueue(){
  if(!offlineQueue.length||!isOnline)return;
  const toSync=[...offlineQueue];
  const failed=[];
  for(const{_ts,...row}of toSync){
    const{error}=await sb.from('sales').insert(row);
    if(error)failed.push({...row,_ts});
  }
  offlineQueue=failed;
  localStorage.setItem('oli_offline_queue',JSON.stringify(offlineQueue));
  const synced=toSync.length-failed.length;
  if(synced>0){toast(`Synced ${synced} offline sale(s)!`,'success');await loadSales()}
  if(failed.length>0){toast(`${failed.length} sale(s) failed to sync`,'error')}
}
```

---

## Bug 4: Refund `soldBy` saved as undefined

**Function:** `confirmRefund()` (around line 1345)

The `refundSale` object uses `refundBy` but `saveSaleToDb` looks for `soldBy`. 

**Fix:** Add `soldBy` to the `refundSale` object:
```js
const refundSale={
  items:refundingSale.items,
  subtotal:-amount,discAmt:0,taxAmt:0,
  total:-amount,payment:'refund',
  cashReceived:null,
  disc:0,tax:0,
  refundOf:refundingSale.id,
  refundReason:reason,
  refundType:type,
  refundBy:currentUser?.name,
  soldBy:currentUser?.name   // add this line
};
```

---

## Bug 5: Fix duplicate `display:none` on install banner

**Element:** `id="installBanner"` (around line 804)

The element has `display:none` written twice in its style attribute.

**Fix:** Find the `installBanner` div and remove the duplicate `display:none` so it only appears once at the start of the style attribute.

---

After all fixes are applied, check for syntax errors and make sure the file is saved.
