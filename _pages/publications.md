---
layout: page
permalink: /publications/
title: Publications
description: 
nav: true
nav_order: 2
---

<!-- _pages/publications.md -->

<!-- Bibsearch Feature -->

{% include bib_search.liquid %}

<!-- Sort Header -->
<div class="pub-sort-header">
  <button id="sort-year-btn" class="sort-year-toggle" onclick="toggleSort()">
    Year <span class="sort-arrow">↓</span>
  </button>
</div>

<div class="publications" id="publications-list">

{% bibliography --query @* --sort_by year,month --group_by year --group_order descending %}

</div>

<script>
(function() {
  var currentOrder = 'desc';

  window.toggleSort = function() {
    currentOrder = currentOrder === 'desc' ? 'asc' : 'desc';
    var container = document.getElementById('publications-list');
    var children = Array.from(container.children);

    var groups = [];
    var current = null;
    children.forEach(function(el) {
      if (el.tagName === 'H2') {
        current = { header: el, list: null };
        groups.push(current);
      } else if (current) {
        current.list = el;
      }
    });

    groups.sort(function(a, b) {
      var yearA = parseInt(a.header.textContent.replace(/[^0-9]/g, ''));
      var yearB = parseInt(b.header.textContent.replace(/[^0-9]/g, ''));
      return currentOrder === 'asc' ? yearA - yearB : yearB - yearA;
    });

    groups.forEach(function(g) {
      container.appendChild(g.header);
      if (g.list) container.appendChild(g.list);
    });

    // Update arrow
    var arrow = document.querySelector('#sort-year-btn .sort-arrow');
    if (arrow) arrow.textContent = currentOrder === 'desc' ? '↓' : '↑';

    renumberPublications();
  };

  function renumberPublications() {
    var items = document.querySelectorAll('#publications-list ol.bibliography > li');
    var total = items.length;
    items.forEach(function(li, i) {
      li.setAttribute('data-pub-number', total - i);
    });
  }

  document.addEventListener('DOMContentLoaded', renumberPublications);
})();
</script>

